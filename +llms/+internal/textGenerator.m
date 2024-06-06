classdef (Abstract) textGenerator
    % This class is undocumented and will change in a future release

    % Copyright 2023-2024 The MathWorks, Inc.

    properties
        %TEMPERATURE   Temperature of generation.
        Temperature {llms.utils.mustBeValidTemperature} = 1

        %TOPPROBABILITYMASS   Top probability mass to consider for generation.
        TopProbabilityMass {llms.utils.mustBeValidTopP} = 1

        %STOPSEQUENCES   Sequences to stop the generation of tokens.
        StopSequences {llms.utils.mustBeValidStop} = {}
    end

    properties (SetAccess=protected)
        %TIMEOUT    Connection timeout in seconds (default 10 secs)
        TimeOut

        %FUNCTIONNAMES   Names of the functions that the model can request calls
        FunctionNames

        %SYSTEMPROMPT   System prompt.
        SystemPrompt = []

        %RESPONSEFORMAT     Response format, "text" or "json"
        ResponseFormat
    end

    properties (Access=protected)
        Tools
        FunctionsStruct
        APIKey
        StreamFun
    end
end
