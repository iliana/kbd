# pylint: disable=missing-docstring

import os
import sys


def main():
    properties = dict(tee_properties())
    properties["build.path"] = "."
    tool = properties["upload.tool"]
    pattern = (
        properties[f"tools.{tool}.upload.pattern"]
        .replace("{path}/", "")
        .replace("{cmd}", f"{{tools.{tool}.cmd}}")
    )
    print(pattern)
    with open(f"output/{sys.argv[1]}/flash.sh", "w", encoding="utf-8") as script:
        os.chmod(script.name, 0o755)
        script.write("#!/usr/bin/env bash\n")
        script.write("""cd "${BASH_SOURCE%/*}" || exit\n""")
        script.write(pattern.format(**PropertyHelper(properties).split()) + "\n")


def tee_properties():
    with open(f"output/{sys.argv[1]}/properties.txt", "w", encoding="utf-8") as output:
        for line in sys.stdin:
            output.write(line)
            yield line.rstrip(os.linesep).split("=", maxsplit=1)


class PropertyHelper:
    def __init__(self, data, path=None):
        self._data = data
        self._path = path or []

    def __getattr__(self, name):
        return PropertyHelper(self._data, path=[*self._path, name])

    def __str__(self):
        return self._data[".".join(self._path)]

    def split(self):
        keys = set(k.split(".", 1)[0] for k in self._data.keys())
        return {k: getattr(self, k) for k in keys}


if __name__ == "__main__":
    main()
