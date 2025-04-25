return {
    encode = function(data_to_encode)
        if type(data_to_encode) ~= "table" then return end

        local encoded_data = "";

        for i, k in pairs(data_to_encode) do
            local data = i .. ":" .. k .. ";";
            encoded_data = encoded_data .. data;
        end

        return encoded_data;
    end,

    decode = function(data_to_decode)
        if type(data_to_decode) ~= "string" then return end

        local decoded_data = {};

        for line in string.gmatch(data_to_decode, "([^;]+)") do
            local index, key = string.match(line, "([^:]+):([^:]+)");

            table.insert(decoded_data, index, key);
        end

        return decoded_data;
    end
}