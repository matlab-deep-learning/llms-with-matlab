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
end
