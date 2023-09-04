function mustBeTextOrEmpty(value)
    if ~isempty(value)
        mustBeTextScalar(value)
    end
end