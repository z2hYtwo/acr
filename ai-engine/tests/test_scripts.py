from pathlib import Path
import subprocess
import pytest
import sys
ROOT = Path(__file__).resolve().parents[2]

@pytest.mark.skipif(sys.platform != "win32", reason="Windows environment check")
def test_windows_environment_check():
    script = ROOT / "scripts/check-env.ps1"
    assert script.is_file(), "P0 environment checker is missing"
    result = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(script)], cwd=ROOT, capture_output=True, text=True)
    assert result.returncode == 0, result.stdout + result.stderr
    assert "Python 3.12" in result.stdout
    assert "Compose" in result.stdout
