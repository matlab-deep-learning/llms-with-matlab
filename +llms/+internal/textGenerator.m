classdef (Abstract) textGenerator
    % This class is undocumented and will change in a future release

    % Copyright 2023-2026 The MathWorks, Inc.

    properties
        %Temperature   Temperature of generation.
        Temperature {llms.utils.mustBeValidTemperature} = "auto"

        %TopP   Top probability mass to consider for generation.
        TopP {llms.utils.mustBeValidProbability} = "auto"

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

    methods
        function hObj = set.Temperature(hObj,value)
            hObj.Temperature = convertCharsToStrings(value);
        end

        function hObj = set.TopP(hObj,value)
            hObj.TopP = convertCharsToStrings(value);
        end

        function hObj = set.StopSequences(hObj,value)
            hObj.StopSequences = string(value);
        end
    end
end
