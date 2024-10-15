classdef verbatimJSON
    % This class is undocumented and will change in a future release

    % Copyright 2024 The MathWorks, Inc.
    properties
        Value (1,1) string
    end
    methods
        function obj = verbatimJSON(str)
            obj.Value = str;
        end
        function json = jsonencode(obj,varargin)
            json = obj.Value;
        end
    end
end
