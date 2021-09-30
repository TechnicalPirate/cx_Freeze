import pytest
import pathlib
import cx_Freeze
import sys

class TestExecutable:

    @pytest.fixture()
    def fix_executable(self):
        fake_script_name = "SomeFakeScript.py"
        return cx_Freeze.Executable(fake_script_name)

    def test___init__(self, mocker):
        """ This method checks the expected initial values for instantiating Exec with only required args"""
        fake_script_name = "SomeFakeScript.py"
        mock_validate = mocker.patch("cx_Freeze.executable.validate_args", return_value=None)
        mock_get_res_file_path = mocker.patch(
            "cx_Freeze.executable.get_resource_file_path", return_value=pathlib.Path("Console")
        )

        exec_instance = cx_Freeze.Executable(fake_script_name)
        assert isinstance(exec_instance.main_script, pathlib.Path)
        assert str(exec_instance.main_script) == fake_script_name
        assert isinstance(exec_instance.init_script, pathlib.Path)
        assert str(exec_instance.init_script) == "Console"
        assert isinstance(exec_instance.base, pathlib.Path)
        assert str(exec_instance.base) == "Console"
        assert exec_instance.target_name.startswith(fake_script_name.split(".", 1)[0])
        assert exec_instance.icon is None
        assert exec_instance.shortcut_name is None
        assert exec_instance.shortcut_dir is None
        assert exec_instance.copyright is None
        assert exec_instance.trademarks is None

        assert mock_get_res_file_path.called_once()
        expected_calls = [
            mocker.call("init_script", None, None),
            mocker.call("target_name", None, None),
            mocker.call("shortcut_name", None, None),
            mocker.call("shortcut_dir", None, None),
        ]
        mock_validate.assert_has_calls(expected_calls)

    def test___repr__(self, fix_executable):
        repr_str = repr(fix_executable)
        assert isinstance(repr_str, str)

    def test_base_get(self, fix_executable):
        base_value = fix_executable.base
        assert isinstance(base_value, pathlib.Path)

    @pytest.mark.parametrize("platform, extension", [("win32", ".exe"), ("darwin", "")])
    def test_base_set(self, mocker, fix_executable, platform, extension):
        mocker.patch.object(sys, "platform", platform)
        mocker.patch("pathlib.Path.exists", return_value=True)  # Force True so we get a path returned
        fix_executable.base = "Console"
        assert isinstance(fix_executable.base, pathlib.Path)
        assert fix_executable._ext == extension

    def test_base_set_raises_config_error_on_none(self, fix_executable):
        with pytest.raises(cx_Freeze.ConfigError):
            fix_executable.base = "SomethingUnexpected"
