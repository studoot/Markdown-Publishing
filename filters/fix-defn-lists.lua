--[[
    Append LaTeX \nopagebreak after parts of definition lists
    that we want to keep with next paragraph
]]

-- Presume that a paragraph with a single, bold element is a title, and should
-- be kept with the next paragraph.
function fix_title(element)
    if #element.content == 1 and element.content[1].tag == "Strong" then
        local strong = element.content[1].content
        if #strong == 1 and strong[1].tag == "Str" then
            table.insert(element.content, pandoc.RawInline('latex', '\\nopagebreak'))
        end
    end
    return element
end

function DefinitionList(block)
    for k, v in pairs(block.content) do
        table.insert(v[1], pandoc.RawInline('latex', '\\nopagebreak'))
    end
    return pandoc.walk_block(block, {Plain = fix_title})
end
