classdef (Abstract) hstructuredOutput < matlab.mock.TestCase
% Tests for completion APIs providing structured output

%   Copyright 2023-2025 The MathWorks, Inc.

    properties(Abstract)
        structuredModel
    end
    
    methods(Test)
        % Test methods
        function generateWithStructuredOutput(testCase)
            import matlab.unittest.constraints.ContainsSubstring
            import matlab.unittest.constraints.StartsWithSubstring
            res = generate(testCase.structuredModel,"Which animal produces honey?",...
                ResponseFormat = struct(commonName = "dog", scientificName = "Canis familiaris"));
            testCase.assertClass(res,"struct");
            testCase.verifySize(fieldnames(res),[2,1]);
            testCase.verifyThat(lower(res.commonName), ContainsSubstring("bee"));
            testCase.verifyThat(res.scientificName, StartsWithSubstring("Apis"));
        end

        function generateListWithStructuredOutput(testCase)
            prototype = struct("plantName",{"appletree","pear"}, ...
                "fruit",{"apple","pear"}, ...
                "edible",[true,true], ...
                "ignore", missing);
            res = generate(testCase.structuredModel,"What is harvested in August?", ResponseFormat = prototype);
            testCase.verifyCompatibleStructs(res, prototype);
        end

        function generateWithNestedStructs(testCase)
            stepsPrototype = struct("explanation",{"a","b"},"assumptions",{"a","b"});
            prototype = struct("steps",stepsPrototype,"final_answer","a");
            res = generate(testCase.structuredModel,"What is the positive root of x^2-2*x+1?", ...
                ResponseFormat=prototype);
            testCase.verifyCompatibleStructs(res,prototype);
        end

        function incompleteJSONResponse(testCase)
            country = ["USA";"UK"];
            capital = ["Washington, D.C.";"London"];
            population = [345716792;69203012];
            prototype = struct("country",country,"capital",capital,"population",population);

            testCase.verifyError(@() generate(testCase.structuredModel, ...
                "What are the five largest countries whose English names" + ...
                " start with the letter A?", ...
                ResponseFormat = prototype, MaxNumTokens=3), "llms:apiReturnedIncompleteJSON");
        end

        function generateWithExplicitSchema(testCase)
            import matlab.unittest.constraints.IsSameSetAs
            schema = iGetSchema();

            genUser = generate(testCase.structuredModel,"Create a sample user",ResponseFormat=schema);
            testCase.verifyClass(genUser,"string");
            genUserDecoded = jsondecode(genUser);
            testCase.verifyClass(genUserDecoded.item,"struct");
            testCase.verifyThat(fieldnames(genUserDecoded.item),...
                IsSameSetAs({'name','age'}) | IsSameSetAs({'number','street','city'}));
        end
    end

    methods
        function verifyCompatibleStructs(testCase,data,prototype)
            testCase.assertClass(data,"struct");
            testCase.assertClass(prototype,"struct");
            arrayfun(@(d) testCase.verifyCompatibleStructsScalar(d,prototype(1)), data);
        end

        function verifyCompatibleStructsScalar(testCase,data,prototype)
            import matlab.unittest.constraints.IsSameSetAs
            testCase.assertClass(data,"struct");
            testCase.assertClass(prototype,"struct");
            testCase.assertThat(fieldnames(data),IsSameSetAs(fieldnames(prototype)));
            for name = fieldnames(data).'
                field = name{1};
                testCase.verifyClass(data.(field),class(prototype.(field)));
                if isstruct(data.(field))
                    testCase.verifyCompatibleStructs(data.(field),prototype.(field));
                end
            end
        end
    end
end

function str = iGetSchema()
% an example from https://platform.openai.com/docs/guides/structured-outputs/supported-schemas
str = string(join({
        '{'
        '    "type": "object",'
        '    "properties": {'
        '        "item": {'
        '            "anyOf": ['
        '                {'
        '                    "type": "object",'
        '                    "description": "The user object to insert into the database",'
        '                    "properties": {'
        '                        "name": {'
        '                            "type": "string",'
        '                            "description": "The name of the user"'
        '                        },'
        '                        "age": {'
        '                            "type": "number",'
        '                            "description": "The age of the user"'
        '                        }'
        '                    },'
        '                    "additionalProperties": false,'
        '                    "required": ['
        '                        "name",'
        '                        "age"'
        '                    ]'
        '                },'
        '                {'
        '                    "type": "object",'
        '                    "description": "The address object to insert into the database",'
        '                    "properties": {'
        '                        "number": {'
        '                            "type": "string",'
        '                            "description": "The number of the address. Eg. for 123 main st, this would be 123"'
        '                        },'
        '                        "street": {'
        '                            "type": "string",'
        '                            "description": "The street name. Eg. for 123 main st, this would be main st"'
        '                        },'
        '                        "city": {'
        '                            "type": "string",'
        '                            "description": "The city of the address"'
        '                        }'
        '                    },'
        '                    "additionalProperties": false,'
        '                    "required": ['
        '                        "number",'
        '                        "street",'
        '                        "city"'
        '                    ]'
        '                }'
        '            ]'
        '        }'
        '    },'
        '    "additionalProperties": false,'
        '    "required": ['
        '        "item"'
        '    ]'
        '}'
}, newline));
end
