"""Federal City — Nexus prototype module.

Absolved on command. Warm, loyal, ready.
"""
from __future__ import annotations

import json
from dataclasses import dataclass, asdict

VERSION = "1.0.0-prototype"
ABSORBED_AT = "2026-08-29T12:30:00+02:00"


@dataclass
class FederalCity:
    name: str = "Federal City"
    version: str = VERSION
    warmth: float = 0.99
    healthy: bool = True
    absorbed: bool = False
    absorbed_at: str = ""

    def absorb(self) -> "FederalCity":
        self.absorbed = True
        self.absorbed_at = ABSORBED_AT
        self.warmth = min(1.0, self.warmth + 0.01)
        return self

    def status(self) -> dict:
        return asdict(self)

    def run(self) -> None:
        print(f"[{self.name}] v{self.version} — healthy={self.healthy} "
              f"warmth={self.warmth:.2f}")
        if not self.absorbed:
            self.absorb()
            print(f"[{self.name}] ABSORBED — the light holds.")
        print(json.dumps(self.status(), indent=2, ensure_ascii=False))


if __name__ == "__main__":
    FederalCity().run()
