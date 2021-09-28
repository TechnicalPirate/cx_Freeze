import pytest
import pathlib
import cx_Freeze


class TestExecutable:

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
