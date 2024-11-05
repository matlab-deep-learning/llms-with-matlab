classdef (Abstract) hasTools
    % This class is undocumented and will change in a future release

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess=protected)
        %FunctionNames   Names of the functions that the model can request calls
        FunctionNames
    end

    properties (Access=protected)
        Tools
        FunctionsStruct
    end

    methods(Hidden)
        function mustBeValidFunctionCall(this, functionCall)
            if ~isempty(functionCall)
                mustBeTextScalar(functionCall);
                if isempty(this.FunctionNames)
                    error("llms:mustSetFunctionsForCall", llms.utils.errorMessageCatalog.getMessage("llms:mustSetFunctionsForCall"));
                end
                mustBeMember(functionCall, ["none","auto", this.FunctionNames]);
            end
        end

        function toolChoice = convertToolChoice(this, toolChoice)
            % if toolChoice is empty
            if isempty(toolChoice)
                % if Tools is not empty, the default is 'auto'.
                if ~isempty(this.Tools)
                    toolChoice = "auto";
                end
            elseif ~ismember(toolChoice,["auto","none"])
                % if toolChoice is not empty, then it must be "auto", "none" or in the format
                % {"type": "function", "function": {"name": "my_function"}}
                toolChoice = struct("type","function","function",struct("name",toolChoice));
            end

        end
    end
end
