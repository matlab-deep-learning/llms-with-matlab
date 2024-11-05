function schema = jsonSchemaFromPrototype(prototype)
% This function is undocumented and will change in a future release

%jsonSchemaFromPrototype Create a JSON Schema matching given prototype

% Copyright 2024 The MathWorks Inc.

if ~isstruct(prototype)
    error("llms:incorrectResponseFormat", ...
        llms.utils.errorMessageCatalog.getMessage("llms:incorrectResponseFormat"));
end

% OpenAI requires top-level to be "type":"object"
if ~isscalar(prototype)
    prototype = struct("result",{prototype});
end

schema = recursiveSchemaFromPrototype(prototype);
end

function schema = recursiveSchemaFromPrototype(prototype)
    if ~isscalar(prototype)
        schema = struct("type","array","items",recursiveSchemaFromPrototype(prototype(1)));
    elseif isstruct(prototype)
        schema = schemaFromStruct(prototype);
    elseif isstring(prototype) || iscellstr(prototype)
        schema = struct("type","string");
    elseif isinteger(prototype)
        schema = struct("type","integer");
    elseif isnumeric(prototype) && ~isa(prototype,'dlarray')
        schema = struct("type","number");
    elseif islogical(prototype)
        schema = struct("type","boolean");
    elseif iscategorical(prototype)
        schema = struct("type","string", ...
            "enum",{categories(prototype)});
    elseif ismissing(prototype)
        schema = struct("type","null");
    else
        error("llms:unsupportedDatatypeInPrototype", ...
            llms.utils.errorMessageCatalog.getMessage("llms:unsupportedDatatypeInPrototype", class(prototype)));
    end
end

function schema = schemaFromStruct(prototype)
fields = string(fieldnames(prototype));

properties = struct();
for fn=fields(:).'
    properties.(fn) = recursiveSchemaFromPrototype(prototype.(fn));
end

% to make jsonencode encode an array
if isscalar(fields)
    fields = {{fields}};
end

schema = struct( ...
    "type","object", ...
    "properties",properties, ...
    "required",fields, ...
    "additionalProperties",false);
end
