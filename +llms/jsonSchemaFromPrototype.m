function str = jsonSchemaFromPrototype(prototype)
%jsonSchemaFromPrototype - create JSON Schema from prototype
%   STR = llms.jsonSchemaFromPrototype(PROTOTYPE) creates a JSON Schema
%   that can be used with openAIChat ResponseFormat.
%
%   Example:
%   >> prototype = struct("name","Alena Zlatkov","age",32);
%   >> schema = llms.jsonSchemaFromPrototype(prototype);
%   >> generate(openAIChat, "Generate a random person", ResponseFormat=schema)
%
%    ans = "{"name":"Emily Carter","age":29}"

% Copyright 2024 The MathWorks, Inc.

str = string(jsonencode(llms.internal.jsonSchemaFromPrototype(prototype),PrettyPrint=true));
end
