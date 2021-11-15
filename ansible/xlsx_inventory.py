#!/usr/bin/env python3

import json
import os
import argparse
import configparser
import six
from openpyxl import load_workbook
from openpyxl.utils.cell import coordinate_from_string, column_index_from_string

try:
    FileNotFoundError
except NameError:
    FileNotFoundError = IOError

default_group = "NO_GROUP"

def main():
    args = parse_args()
    try:
        wb = load_workbook(args.file if args.file is not None else "example.xlsx")
        table = args.sheet if args.sheet is not None else "Inventory"
        sheet = wb[table]
        inventory = sheet_to_inventory(
            group_by_col=args.group_by_col if args.group_by_col is not None else "B",
            hostname_col=args.hostname_col if args.hostname_col is not None else "A",
            sheet=sheet,
        )
        if args.list:
            print(json.dumps(inventory, indent=4, sort_keys=True, default=str))
        elif args.host:
            try:
                print(
                    json.dumps(
                        inventory["_meta"]["hostvars"][args.host],
                        indent=4,
                        sort_keys=True,
                        default=str,
                    )
                )
            except KeyError as e:
                print('\033[91mHost "%s" not Found!\033[0m' % e)
                print(e)
    except FileNotFoundError as e:
        print(
            "\033[91mFile Not Found! Check %s configuration file!"
            " Is the `xlsx_inventory_file` path setting correct?\033[0m" % config_path
        )
        print(e)
        exit(1)
    except KeyError as e:
        print(
            "\033[91mKey Error! Check %s configuration file! Is the `sheet` name setting correct?\033[0m"
            % config_path
        )
        print(e)
        exit(1)
    exit(0)

def parse_args():
    arg_parser = argparse.ArgumentParser(
        description="Excel Spreadsheet Inventory Module"
    )
    group = arg_parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--list", action="store_true", help="List active servers")
    group.add_argument(
        "--host", help="List details about the specified host", default=None
    )
    arg_parser.add_argument(
        "--file", default=None, help="Excel Spreadsheet file used by xlsx_inventory.py"
    )
    arg_parser.add_argument(
        "--group-by-col", default=None, help="Column to group hosts by (i.E. `B`)"
    )
    arg_parser.add_argument(
        "--hostname-col", default=None, help="Column containing the hostnames"
    )
    arg_parser.add_argument(
        "--sheet", default=None, help="Name of the Sheet, used by xlsx_inventory.py"
    )
    return arg_parser.parse_args()


def sheet_to_inventory(group_by_col, hostname_col, sheet):
    if isinstance(group_by_col, six.string_types):
        group_by_col = (
            column_index_from_string(coordinate_from_string(group_by_col + "1")[0]) - 1
        )
    if isinstance(hostname_col, six.string_types):
        hostname_col = (
            column_index_from_string(coordinate_from_string(hostname_col + "1")[0]) - 1
        )

    groups = {"_meta": {"hostvars": {}}}
    rows = list(sheet.rows)

    for row in rows[1:]:
        host = row[hostname_col].value
        if host is None:
            continue
        group = row[group_by_col].value
        if group is None:
            group = default_group
        if group not in groups.keys():
            groups[group] = {"hosts": [], "vars": {
                "ansible_connection": "ssh",
                "ansible_user": "test"
                }}
        groups[group]["hosts"].append(host)
        groups["_meta"]["hostvars"][row[hostname_col].value] = {}
        for idx, var_name in enumerate(rows[0]):
            if var_name.value is None:
                var_name.value = "xlsx_" + var_name.coordinate
            if row[idx].value is not None:
                groups["_meta"]["hostvars"][row[0].value][
                    var_name.value.lower().replace(" ", "_")
                ] = row[idx].value

    return groups

if __name__ == "__main__":
    main()
