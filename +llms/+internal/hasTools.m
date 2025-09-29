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
        function mustBeValidFunctionCall(this, functionCall, functionNames)
            if nargin < 3
                functionNames = this.FunctionNames;
            end

            if ~isempty(functionCall)
                mustBeTextScalar(functionCall);
                if isempty(functionNames) && ~ismember(functionCall, ["auto", "none"])
                    error("llms:mustSetFunctionsForCall", llms.utils.errorMessageCatalog.getMessage("llms:mustSetFunctionsForCall"));
                end
                mustBeMember(functionCall, ["none","auto","required", functionNames]);
            end
        end

        function toolChoice = convertToolChoice(this, toolChoice, functionNames)
            if nargin < 3
                functionNames = this.FunctionNames;
            end

            % if toolChoice is empty
            if isempty(toolChoice)
                % if Tools is not empty, the default is 'auto'.
                if ~isempty(this.Tools)
                    toolChoice = "auto";
                end
            elseif ismember(toolChoice, ["auto", "none"]) && isempty(functionNames)
                toolChoice = strings(1,0);
            elseif ~ismember(toolChoice,["auto","none","required"])
                % if toolChoice is not empty, then it must be "auto", "none",
                % "required", or in the format {"type": "function", "function":
                % {"name": "my_function"}}
                toolChoice = struct("type","function","function",struct("name",toolChoice));
            end

        end
    end
end
