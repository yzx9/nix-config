{ icons, ... }:

{
  plugins.dap = {
    enable = true;

    signs = {
      dapBreakpoint = {
        text = icons.DapBreakpoint;
        texthl = "DiagnosticInfo";
      };

      dapBreakpointCondition = {
        text = icons.DapBreakpointCondition;
        texthl = "DiagnosticInfo";
      };

      dapBreakpointRejected = {
        text = icons.DapBreakpointRejected;
        texthl = "DiagnosticError";
      };

      dapLogPoint = {
        text = icons.DapLogPoint;
        texthl = "DiagnosticInfo";
      };

      dapStopped = {
        text = icons.DapStopped;
        texthl = "DiagnosticWarn";
      };
    };
  };
}
