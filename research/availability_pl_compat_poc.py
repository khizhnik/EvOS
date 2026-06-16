#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


DEFAULT_MACOSX_AVAIL = Path(
    "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/"
    "Developer/SDKs/MacOSX.sdk/usr/include/AvailabilityVersions.h"
)

DEFAULT_DRIVERKIT_AVAIL = Path(
    "/Applications/Xcode.app/Contents/Developer/Platforms/DriverKit.platform/"
    "Developer/SDKs/DriverKit.sdk/System/DriverKit/usr/include/AvailabilityVersions.h"
)

DEFINE_RE = re.compile(
    r"^#define\s+(?P<name>__(?:MAC|IPHONE)_[A-Za-z0-9_]+)\s+(?P<value>\d+)\s*$"
)


@dataclass(frozen=True)
class AvailabilityData:
    mac_tokens: list[str]
    ios_tokens: list[str]


def parse_identifiers(path: Path) -> AvailabilityData:
    mac_tokens: list[str] = []
    ios_tokens: list[str] = []
    seen_mac: set[str] = set()
    seen_ios: set[str] = set()

    for line in path.read_text().splitlines():
        match = DEFINE_RE.match(line)
        if not match:
            continue

        name = match.group("name")
        if name.startswith("__MAC_"):
            token = name.removeprefix("__MAC_").replace("_", ".")
            if token not in seen_mac:
                mac_tokens.append(token)
                seen_mac.add(token)
        elif name.startswith("__IPHONE_"):
            token = name.removeprefix("__IPHONE_").replace("_", ".")
            if token not in seen_ios:
                ios_tokens.append(token)
                seen_ios.add(token)

    return AvailabilityData(mac_tokens=mac_tokens, ios_tokens=ios_tokens)


def token_to_macro_fragment(kind: str, token: str) -> str:
    parts = token.split(".")
    if kind == "ios":
        major, minor = parts[0], parts[1]
        value = f"{int(major):d}{int(minor):02d}00"
        str_suffix = f"__IPHONE_{major}_{minor}"
        return "\n".join(
            [
                f"#if defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__ >= {value}",
                f"#define __DARWIN_ALIAS_STARTING_IPHONE_{str_suffix}(x) x",
                "#else",
                f"#define __DARWIN_ALIAS_STARTING_IPHONE_{str_suffix}(x)",
                "#endif",
            ]
        )

    major = int(parts[0])
    minor = int(parts[1])
    rel = int(parts[2]) if len(parts) > 2 else 0
    if major < 10 or (major == 10 and minor < 10):
        value = f"{major}{minor}0"
        str_suffix = f"__MAC_{major}_{minor}"
    else:
        value = f"{major}{minor:02d}{rel:02d}"
        str_suffix = f"__MAC_{major}_{minor}_{rel}" if rel > 0 else f"__MAC_{major}_{minor}"
    return "\n".join(
        [
            f"#if defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= {value}",
            f"#define __DARWIN_ALIAS_STARTING_MAC_{str_suffix}(x) x",
            "#else",
            f"#define __DARWIN_ALIAS_STARTING_MAC_{str_suffix}(x)",
            "#endif",
        ]
    )


def validate_tokens(kind: str, tokens: Iterable[str]) -> list[str]:
    tokens = list(tokens)
    pattern = re.compile(r"^\d+(?:\.\d+){1,2}$")
    bad = [t for t in tokens if not pattern.match(t)]
    if bad:
        raise ValueError(f"{kind} tokens do not match expected format: {bad[:10]}")
    return tokens


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Reconstruct availability.pl token streams from AvailabilityVersions.h"
    )
    parser.add_argument("--macosx", type=Path, default=DEFAULT_MACOSX_AVAIL)
    parser.add_argument("--driverkit", type=Path, default=DEFAULT_DRIVERKIT_AVAIL)
    parser.add_argument("--sample", action="store_true", help="Print a sample macro fragment")
    args = parser.parse_args()

    mac = parse_identifiers(args.macosx)
    driverkit = parse_identifiers(args.driverkit)

    mac_tokens = validate_tokens("macOS", mac.mac_tokens)
    ios_tokens = validate_tokens("iOS", mac.ios_tokens)

    print("MACOSX_TOKEN_STREAM")
    print(" ".join(mac_tokens))
    print()
    print("IOS_TOKEN_STREAM")
    print(" ".join(ios_tokens))
    print()

    print(f"MACOSX_COUNT={len(mac_tokens)}")
    print(f"IOS_COUNT={len(ios_tokens)}")
    print(f"DRIVERKIT_MATCHES_MACOSX={driverkit.mac_tokens == mac_tokens}")
    print(f"DRIVERKIT_MATCHES_IOS={driverkit.ios_tokens == ios_tokens}")
    print()

    if args.sample:
        print("SAMPLE: __MAC_15_0 -> 15.0")
        print(token_to_macro_fragment("macos", "15.0"))
        print()
        print("SAMPLE: __MAC_10_10_3 -> 10.10.3")
        print(token_to_macro_fragment("macos", "10.10.3"))
        print()
        print("SAMPLE: __IPHONE_14_8 -> 14.8")
        print(token_to_macro_fragment("ios", "14.8"))
        print()

    print("PARSER_CHECK")
    print("availability.pl output is whitespace-delimited version tokens")
    print("make_symbol_aliasing.sh consumes those tokens with 'for ver in $()' and 'tr . space'")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
