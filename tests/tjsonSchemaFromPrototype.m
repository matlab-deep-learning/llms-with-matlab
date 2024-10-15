classdef tjsonSchemaFromPrototype < matlab.unittest.TestCase
% Unit tests for llms.internal.jsonSchemaFromPrototype and llms.jsonSchemaFromPrototype

%   Copyright 2024 The MathWorks, Inc.

    methods (Test)
        function simpleExample(testCase)
            import matlab.unittest.constraints.IsSameSetAs

            prototype = struct("name","James","age",20);
            schema = llms.internal.jsonSchemaFromPrototype(prototype);

            testCase.assertClassSchema(schema)

            % Now check this actually matches our specific input
            testCase.assertThat(schema.required, ...
                IsSameSetAs(string(fieldnames(prototype))));
            testCase.assertClass(schema.properties.name,"struct");
            testCase.verifyEqual(schema.properties.name.type,"string");
            testCase.verifyEqual(schema.properties.age.type,"number");
        end

        function nonScalarFields(testCase)
            import matlab.unittest.constraints.IsSameSetAs

            prototype = struct("values",[1.2,3.4,5.67]);
            schema = llms.internal.jsonSchemaFromPrototype(prototype);

            testCase.assertClassSchema(schema);

            % Now check this actually matches our specific input
            testCase.assertThat(fieldnames(schema.properties), ...
                IsSameSetAs(fieldnames(prototype)));
            testCase.assertClass(schema.properties.values,"struct");
            testCase.verifyEqual(schema.properties.values.type,"array");
            testCase.verifyEqual(schema.properties.values.items, ...
                struct("type","number"));
        end

        function nonScalarTopLevel(testCase)
            % OpenAI says the top level must have "type":"object", so we need
            % to wrap a nonscalar toplevel request into another object.
            import matlab.unittest.constraints.IsSameSetAs

            prototype = struct("values",[1.2,3.4,5.67]);
            prototype = [prototype;prototype];
            schema = llms.internal.jsonSchemaFromPrototype(prototype);
            schema1 = llms.internal.jsonSchemaFromPrototype(prototype(1));

            testCase.assertClassSchema(schema);

            % Now check this actually matches our specific input
            testCase.assertEqual(schema.required,{"result"});
            testCase.assertEqual(schema.properties.result.type,"array");
            testCase.assertEqual(schema.properties.result.items,schema1);
        end

        function allScalarTypes(testCase)
            import matlab.unittest.constraints.IsSameSetAs
            import matlab.unittest.constraints.HasField
            prototype = struct( ...
                "string","string", ...
                "cellstr",{{''}}, ...
                "integer",uint8(42), ...
                "number",4.2, ...
                "boolean",true, ...
                "object",struct("a",1), ...
                "array",{[1,2,3]}, ...
                "enum",categorical("a",["a","b","c"]), ...
                "missing", missing);
            schema = llms.internal.jsonSchemaFromPrototype(prototype);

            testCase.assertClassSchema(schema);

            testCase.assertThat(schema.required, ...
                IsSameSetAs(string(fieldnames(prototype))));
            testCase.verifyEqual(schema.properties.string.type,"string");
            testCase.verifyThat(schema.properties.string,~HasField("enum"));
            testCase.verifyEqual(schema.properties.cellstr.type,"string");
            testCase.verifyThat(schema.properties.cellstr,~HasField("enum"));
            testCase.verifyEqual(schema.properties.integer.type,"integer");
            testCase.verifyEqual(schema.properties.number.type,"number");
            testCase.verifyEqual(schema.properties.boolean.type,"boolean");
            testCase.verifyEqual(schema.properties.object.type,"object");
            testCase.verifyEqual(schema.properties.array.type,"array");
            testCase.verifyEqual(schema.properties.enum.type,"string");
            testCase.assertThat(schema.properties.enum,HasField("enum"));
            % orientation does not matter
            testCase.verifyEqual(schema.properties.enum.enum,{'a','b','c'}.');
            testCase.verifyEqual(schema.properties.missing.type,"null");
        end

        function userFrontend(testCase)
            import matlab.unittest.constraints.StartsWithSubstring
            import matlab.unittest.constraints.EndsWithSubstring
            import matlab.unittest.constraints.ContainsSubstring

            schema = llms.jsonSchemaFromPrototype(struct("str","","int",uint16(1)));

            testCase.assertClass(schema,"string");
            testCase.verifyThat(schema,StartsWithSubstring("{"));
            testCase.verifyThat(schema,EndsWithSubstring("}"));
            testCase.verifyThat(schema,ContainsSubstring('"type": "integer"'));
        end

        function errors(testCase)
            testCase.verifyError( ...
                @() llms.internal.jsonSchemaFromPrototype(struct("a",datetime)), ...
                "llms:unsupportedDatatypeInPrototype");
        end
    end

    methods
        function assertClassSchema(testCase,schema)
            import matlab.unittest.constraints.IsSupersetOf
            import matlab.unittest.constraints.IsSameSetAs

            testCase.assertClass(schema,"struct");
            % fields as required by OpenAI
            testCase.assertThat(fieldnames(schema),...
                IsSupersetOf({'type','properties','required',...
                    'additionalProperties'}));
            testCase.verifyEqual(schema.type,"object");
            testCase.verifyEqual(schema.additionalProperties,false);
            testCase.assertClass(schema.properties,"struct");
            required = schema.required;
            if iscell(required)
                required = required{1}{1};
            end
            testCase.assertThat(string(fieldnames(schema.properties)), ...
                IsSameSetAs(required));
        end
    end
end
