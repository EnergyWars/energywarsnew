def _skip(text, index):
    while text[index] in " \t\r\n,":
        index += 1
    return index


def _value_end(text, index):
    depth = 0
    quoted = False
    while True:
        char = text[index]
        if quoted:
            quoted = char != '"'
        elif char == '"':
            quoted = True
        elif char in "([{":
            depth += 1
        elif char in ")]}":
            if depth == 0:
                return index
            depth -= 1
        elif char == "," and depth == 0:
            return index
        index += 1


def parse_dict(text, start):
    entries = {}
    index = start + 1
    while True:
        index = _skip(text, index)
        if text[index] == "}":
            return entries
        if text[index] == '"':
            close = text.index('"', index + 1)
            key = text[index + 1:close]
            index = close + 1
        else:
            colon = text.index(":", index)
            key = text[index:colon].strip()
            index = colon
        index = _skip_spaces(text, index + 1)
        end = _value_end(text, index)
        children = parse_dict(text, index) if text[index] == "{" else None
        entries[key] = (index, end, children)
        index = end


def _skip_spaces(text, index):
    while text[index] in " \t":
        index += 1
    return index


def find_span(entries, path):
    node = None
    for key in path:
        if entries is None or key not in entries:
            raise KeyError(".".join(path))
        node = entries[key]
        entries = node[2]
    return node[0], node[1]
