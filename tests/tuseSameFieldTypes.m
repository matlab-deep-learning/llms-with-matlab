classdef tuseSameFieldTypes < matlab.unittest.TestCase
% Unit tests for llms.internal.useSameFieldTypes

%   Copyright 2024 The MathWorks, Inc.

    methods(Test)
        function allSupportedDatatypes(testCase)
            % except for alternatives, because those cannot be tested with a simple verifyEqual
            prototype = struct(...
                "string", "", ...
                "char", {''}, ...
                "double", 1, ...
                "logical", true, ...
                "categorical", categorical("green",["red","green","blue","seashell"]));
            data = struct(...
                "string", {''}, ...
                "char", "", ...
                "double", uint8(1), ...
                "logical", 1, ...
                "categorical", "green");

            converted = llms.internal.useSameFieldTypes(data,prototype);
            testCase.verifyEqual(converted, prototype);
        end

        function arrayOfStruct(testCase)
            prototype = struct("a", [true, true]);
            data = struct("a",[1,1,0]);
            expected = struct("a",[true,true,false]);

            testCase.verifyEqual(llms.internal.useSameFieldTypes(data,prototype), expected);
        end

        function noErrors(testCase)
            % If the LLM sends back unexpected data, we do not want to
            % throw an error in the useSameFieldTypes function
            prototype = struct("a",1);
            data = struct("b",1);

            testCase.verifyEqual(llms.internal.useSameFieldTypes(data,prototype),data);
        end
    end

end
