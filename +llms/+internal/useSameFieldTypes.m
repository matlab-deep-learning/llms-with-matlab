function data = useSameFieldTypes(data,prototype)
% This function is undocumented and will change in a future release

%useSameFieldTypes  Change struct field data types to match prototype 

% Copyright 2024 The MathWorks Inc.

if ~isscalar(data)
    data = arrayfun( ...
        @(d) llms.internal.useSameFieldTypes(d,prototype), data, ...
        UniformOutput=false);
    data = vertcat(data{:});
    return
end

data = alignTypes(data, prototype);
end

function data = alignTypes(data, prototype)
switch class(prototype)
    case "struct"
        prototype = prototype(1);
        if isscalar(data)
            if isequal(sort(fieldnames(data)),sort(fieldnames(prototype)))
                for field_c = fieldnames(data).'
                    field = field_c{1};
                    data.(field) = alignTypes(data.(field),prototype.(field));
                end
            end
        else
            data = arrayfun(@(d) alignTypes(d,prototype), data, UniformOutput=false);
            data = vertcat(data{:});
        end
    case "string"
        data = string(data);
    case "categorical"
        data = categorical(string(data),categories(prototype));
    case "missing"
        data = missing;
    otherwise
        data = cast(data,"like",prototype);
end
end
