classdef tresponseStreamer < matlab.unittest.TestCase
% Tests for llms.stream.reponseStreamer
%
% This test file contains unit tests, with a specific focus on edge cases that
% are hard to trigger in end-to-end tests.

%   Copyright 2024 The MathWorks, Inc.

    methods (Test)
        function singleResponse(testCase)
            s = tracingStreamer;
            inp = 'data: {"choices":[{"content_filter_results":{},"delta":{"content":"foo","role":"assistant"}}]}';
            inp = [inp newline 'data: [DONE]'];
            inp = unicode2native(inp,"UTF-8").';
            testCase.verifyTrue(s.doPutData(inp,false));
            testCase.verifyEqual(s.StreamFun(),"foo");
        end

        function skipEmpty(testCase)
            s = tracingStreamer;
            inp = [...
                'data: {"choices":[{"content_filter_results":{},"delta":{"content":"foo","role":"assistant"}}]}' newline ...
                'data: {"choices":[]}' newline ...
                'data: [DONE]'];
            inp = unicode2native(inp,"UTF-8").';
            testCase.verifyTrue(s.doPutData(inp,false));
            testCase.verifyEqual(s.StreamFun(),"foo");
        end

        function splitResponse(testCase)
            % it can happen that the server sends packets split in the
            % middle of a JSON object. Hard to trigger on purpose.
            s = tracingStreamer;
            inp = 'data: {"choices":[{"content_filter_results":{},"delta":{"content":"foo","role":"assistant"}}]}';
            inp = unicode2native(inp,"UTF-8").';
            testCase.verifyFalse(s.doPutData(inp(1:42),false));
            testCase.verifyFalse(s.doPutData(inp(43:end),false));
            testCase.verifyEqual(s.StreamFun(),"foo");
        end

        function ollamaFormat(testCase)
            s = tracingStreamer;
            inp = '{"model":"mistral","created_at":"2024-06-07T07:43:30.658793Z","message":{"role":"assistant","content":" Hello"},"done":false}';
            inp = unicode2native(inp,"UTF-8").';
            testCase.verifyFalse(s.doPutData(inp,false));
            inp = '{"model":"mistral","created_at":"2024-06-07T07:43:30.658793Z","message":{"role":"assistant","content":" World"},"done":true}';
            inp = unicode2native(inp,"UTF-8").';
            testCase.verifyTrue(s.doPutData(inp,false));
            testCase.verifyEqual(s.StreamFun(),[" Hello"," World"]);
        end

        function badJSON(testCase)
            s = tracingStreamer;
            inp = 'data: {"choices":[{"content_filter_results":{};"delta":{"content":"foo","role":"assistant"}}]}';
            inp = [inp newline inp];
            inp = unicode2native(inp,"UTF-8").';
            testCase.verifyError(@() s.doPutData(inp,false),'llms:stream:responseStreamer:InvalidInput');
            testCase.verifyEmpty(s.StreamFun());
        end
    end
end

function s = tracingStreamer
    data = strings(1, 0);
    function seen = sf(str)
        % Append streamed text to an empty string array of length 1
        if nargin > 0
            data = [data, str];
        end
        seen = data;
    end
    s = llms.stream.responseStreamer(@sf);
end
