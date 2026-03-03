import unittest
from unittest.mock import patch
import p4tc
from p4tc import P4TCError, Transport, P4TCObjType

class TestP4TCPythonAPI(unittest.TestCase):
    
    def test_config_builder_and_provision(self):
        # Test successful provisioning
        try:
            p4tc.provision(pipeline_name="test_pipe", template_dir="/tmp/")
            success = True
        except P4TCError:
            success = False
        self.assertTrue(success, "Provisioning should not raise an error in mock mode")

    def test_context_manager_lifecycle(self):
        # Test that the context manager correctly enters and exits
        with p4tc.context(transport="netlink") as ctx:
            self.assertIsNotNone(ctx)
            self.assertEqual(ctx.transport, Transport.NETLINK)
            
            # Test table creation within context
            table = ctx.table("test_pipe", "cb/my_table")
            self.assertEqual(table.pipeline, "test_pipe")
            self.assertEqual(table.path, "cb/my_table")

    def test_fluent_action_entry(self):
        with p4tc.context() as ctx:
            table = ctx.table("test_pipe", "cb/my_table")
            
            # This shouldn't crash
            table.add_entry(
                key="192.168.1.1",
                action_name="cb/drop",
                params={"reason": "policy"}
            )
            table.entry(
                key="10.0.0.1",
                action={"name": "cb/forward", "params": {"port": 1}}
            )

    @patch('p4tc._p4tc.lib')
    def test_error_handling(self, mock_lib):
        # Simulate a C-level failure (return code < 0)
        mock_lib.p4tc_provision.return_value = -1
        
        with self.assertRaises(P4TCError) as context:
            p4tc.provision("fail_pipe", "/tmp/")
        
        self.assertTrue("Failed to provision" in str(context.exception))

if __name__ == '__main__':
    unittest.main()
