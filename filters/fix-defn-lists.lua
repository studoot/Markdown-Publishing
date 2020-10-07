--[[
    Append LaTeX \nopagebreak after parts of definition lists
    that we want to keep with next paragraph
]]

-- An element that contains a single bold piece of text is presumed to be a title.
function is_title(element)
    if #element.content == 1 and element.content[1].tag == "Strong" then
        local strong = element.content[1].content
        return #strong == 1 and strong[1].tag == "Str" 
    end
    return false
end

function DefinitionList(block)
    -- DefinitionList has a list of definitions
    --      block.content[1..n] = definitions
    --
    -- Each definition (defn) has:
    --      defn[1] = list of inlines making up the text of the term being defined
    --      defn[2] = list of blocks making up the definition
    for k, defn_item in pairs(block.content) do
        local term = defn_item[1]
        local definition = defn_item[2]
        -- Stop page breaks immediately after the term being defined
        table.insert(term, pandoc.RawInline('latex', '\\nopagebreak'))
        for k_in, definition_part in pairs(definition) do
            -- Check each element of the definition to see if it looks like a
            -- title and if so, stop page breaks immediately after it.
            if is_title(definition_part[1]) then
                table.insert(definition_part[1].content, pandoc.RawInline('latex', '\\nopagebreak'))
            end
        end
    end
    return block
end
