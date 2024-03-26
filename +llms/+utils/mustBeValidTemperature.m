function mustBeValidTemperature(value)
    validateattributes(value, {'numeric'}, {'real', 'scalar', 'nonnegative', 'nonsparse', '<=', 2})
end