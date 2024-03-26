function mustBeValidPenalty(value)
    validateattributes(value, {'numeric'}, {'real', 'scalar', 'nonsparse', '<=', 2, '>=', -2})
end