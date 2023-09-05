classdef (Sealed) openAIFunction
%openAIFunction   Define a function
%
%   FUNC = openAIFunction(NAME, DESCRIPTION) creates an open AI function
%   object with the specified NAME and DESCRIPTION.
%
%   openAIFunction Functions:
%       openAIFunction - Define a function.
%       addParameter   - Add parameter to the function.
%
%   openAIFunction Properties:
%       FunctionName   - Name of the function.
%       Description    - Description of the function.
%       Parameters     - Parameters of function.
%
%   Example:
%     % Create an OpenAI function object
%     func = openAIFunction("editDistance", "Find edit distance between two strings or documents");
%
%     % Add two parameter with type and description
%     func = addParameter(func, "str1", type="string", description="Source string.");
%     func = addParameter(func, "str2", type="string", description="Target string.");

% Copyright 2023 The MathWorks, Inc.

    properties(SetAccess=private)
        %FUNCTIONNAME   Name of the function.
        FunctionName

        %DESCRIPTION   Description of the function.
        Description

        %PARAMETERS   Parameters of function.
        Parameters = struct()
    end

    methods
        function this = openAIFunction(name, description)
            arguments
                name (1,1) {mustBeNonzeroLengthText}
                description {llms.utils.mustBeTextOrEmpty} = []
            end

            this.FunctionName = name;
            this.Description = description;
        end

        function this = addParameter(this, parameterName, propertyName, propertyValue, nvp)
            %addParameter   Add parameter to the function
            %
            %   FUNC = addParameter(FUNC, parameterName, propertyName, propertyValue)
            %   adds a parameter to the function signature with name parameterName and
            %   properties propertyName with value PROPERTYVALUE. Inputs propertyName and
            %   propertyValue can be specified repeatedly. The values
            %   accepted for propertyNames are "type", "description" and
            %   "enum". Each propertyName will accept different for propertyValue: 
            %   - type: accepts "string", "number", "integer", "object", "boolean",
            %       "null" and any combination of those values.
            %   - description: accepts text scalar.
            %   - enum: accepts string vectors of text.
            %
            %   FUNC = addParameter(____, RequiredParameter=TF), specifies
            %   if the parameter is required.
            %
            %   Example:
            %   % Create an OpenAI function object
            %   f = openAIFunction("editDistance", "Find edit distance between two strings or documents");
            %
            %   % Add two parameter with type and description
            %   f = addParameter(f, "str1", type="string", description="Source string.");
            %   f = addParameter(f, "str2", type="string", description="Target string.");

            arguments
                this (1,1) openAIFunction
                parameterName (1,1) {mustBeNonzeroLengthText, mustBeValidVariableName}
            end
            arguments(Repeating)
                propertyName (1,1) {mustBeNonzeroLengthText, mustBeMember(propertyName, {'type', 'enum', 'description'})}
                propertyValue (1,:) {mustBeNonzeroLengthText, validatePropertyValue(propertyValue, propertyName)}
            end
            arguments
                nvp.RequiredParameter (1,1) logical = true
            end

            if isfield(this.Parameters,parameterName)
                error("llms:parameterMustBeUnique", ...
                    llms.utils.errorMessageCatalog.getMessage("llms:parameterMustBeUnique", parameterName));
            end

            properties = struct();

            % Properties are optional
            if ~isempty(propertyName)
                for i=1:length(propertyName)
                    properties.(propertyName{i}) = propertyValue{i};
                end
            end

            this.Parameters.(parameterName) = properties;
            this.Parameters.(parameterName).required = nvp.RequiredParameter;
        end
    end

    methods(Hidden)
        function funStruct = encodeStruct(this)
            %encodeStruct   Encode the function object as a struct

            funStruct = struct();
            funStruct.name = this.FunctionName;

            if ~isempty(this.Description)
                funStruct.description = this.Description;
            end

            funStruct.parameters = struct();

            % The API requires type="object"
            funStruct.parameters.type = "object";

            funStruct.parameters.properties = struct();
            
            requiredArguments = [];
            parameterNames = string(fieldnames(this.Parameters));
            for i=1:length(parameterNames)
                parameterStruct = this.Parameters.(parameterNames(i));

                if parameterStruct.required
                    requiredArguments = [requiredArguments,parameterNames(i)]; %#ok
                end

                % "required" should not be a property when sending to the api
                parameterStruct = rmfield(parameterStruct,"required");

                % enum needs to be encoded as array
                if isfield(parameterStruct, "enum") && numel(parameterStruct.enum)==1
                    parameterStruct.enum = {parameterStruct.enum};
                end

                funStruct.parameters.properties.(parameterNames(i)) = parameterStruct;
            end

            % Only create the "required" field if there are required arguments
            if ~isempty(requiredArguments)
                funStruct.parameters.required = requiredArguments;
                if numel(requiredArguments)==1
                    % This will force jsonencode to see "required" as an array
                    funStruct.parameters.required = {funStruct.parameters.required};
                end           
            end
        end
    end
end

function mustBeValidVariableName(value)
if ~isvarname(value)
    error("llms:mustBeVarName", llms.utils.errorMessageCatalog.getMessage("llms:mustBeVarName"));
end
end

function validatePropertyValue(value,name)
switch(name)
    case "type"
        validatePropertyType(value);
    case "description"
        validatePropertyDescription(value);
    case "enum"
        validatePropertyEnum(value);
end
end

function validatePropertyType(value)
validValues = ["string", "number", "integer", "object", "boolean", "null"];
mustBeMember(value, validValues);
end

function validatePropertyDescription(value)
mustBeTextScalar(value) 
end

function validatePropertyEnum(value)
if ~llms.utils.isUnique(value)
    error("llms:mustBeUnique", llms.utils.errorMessageCatalog.getMessage("llms:mustBeUnique"));
end
end