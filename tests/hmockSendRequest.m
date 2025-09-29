classdef hmockSendRequest <  matlab.mock.TestCase
%Helper method(s) for working with the mock framework.

%   Copyright 2025 The MathWorks, Inc.

    methods
        function [sendRequestMock, sendRequestBehaviour] = setUpSendRequestMock(testCase)
            [sendRequestMock,sendRequestBehaviour] = ...
                createMock(testCase, AddedMethods="sendRequest");
            testCase.assignOutputsWhen( ...
                withAnyInputs(sendRequestBehaviour.sendRequest),...
                testCase.responseMessage("Hello"),"This output is unused with Stream=false");
        end
    end
end