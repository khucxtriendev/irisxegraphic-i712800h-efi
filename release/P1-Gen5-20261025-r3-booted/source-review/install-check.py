"""Exercise success and partial-failure rollback using temporary fake bundles."""
import importlib.util
import json
import tempfile
from pathlib import Path

source = Path(__file__).resolve().parents[1] / "scripts/cai_dat_nhanh.py"
spec = importlib.util.spec_from_file_location("quick_install", source)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
with tempfile.TemporaryDirectory(prefix="p1-install-check-") as temporary:
    root = Path(temporary)
    for fail in [False, True]:
        case = root / str(fail)
        pairs = []
        for name in ["kext", "metal"]:
            src, dest = case / (name + "-source"), case / name
            src.mkdir(parents=True);dest.mkdir()
            (src / "binary").write_text("new-" + name)
            (dest / "binary").write_text("old-" + name)
            (dest / "extra-old").write_text("must disappear on success")
            pairs.append((name, src, dest))
        def verify(path):
            if fail and path == pairs[1][2]:
                raise RuntimeError("simulated final Metal validation failure")
        backup = case / "backup"
        try:
            module.install_transaction(pairs, backup, verify)
            assert not fail
        except RuntimeError:
            assert fail
        for name, src, dest in pairs:
            assert (backup / name / "binary").read_text() == "old-" + name
            if fail:
                assert module.tree_hash(dest) == module.tree_hash(backup / name)
            else:
                assert module.tree_hash(src) == module.tree_hash(dest)
        state = json.loads((backup / "transaction.json").read_text())["state"]
        assert state.startswith("rolled back" if fail else "installed")
print("PASS: two-component installation and partial-failure rollback, temporary bundles only; no live EFI/system writes.")
