classdef (Abstract) textGenerator
    % This class is undocumented and will change in a future release

    % Copyright 2023-2024 The MathWorks, Inc.

    properties
        %Temperature   Temperature of generation.
        Temperature {llms.utils.mustBeValidTemperature} = 1

        %TopP   Top probability mass to consider for generation.
        TopP {llms.utils.mustBeValidTopP} = 1

        %StopSequences   Sequences to stop the generation of tokens.
        StopSequences {llms.utils.mustBeValidStop} = {}
    end

    properties (SetAccess=protected)
        %TimeOut    Connection timeout in seconds (default 10 secs)
        TimeOut

        %SystemPrompt   System prompt.
        SystemPrompt = []

        %ResponseFormat     Response format, "text" or "json"
        ResponseFormat
    end

    properties (Access=protected)
        StreamFun
    end
end
