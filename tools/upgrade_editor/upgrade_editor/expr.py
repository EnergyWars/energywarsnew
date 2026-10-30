import re

FUNCTIONS = frozenset(("min", "max", "abs", "sqrt", "exp", "ln", "log", "log10", "floor", "ceil", "round", "pow", "sign"))
CONSTANTS = frozenset(("pi", "e"))
SCOPE = frozenset(("level", "base", "build", "max", "growth", "value"))
MAX_LENGTH = 400
TOKEN = re.compile(r"\s*(?:(\d+\.?\d*(?:e[+-]?\d+)?|\.\d+(?:e[+-]?\d+)?)|([A-Za-z_][A-Za-z_0-9]*)|(\*\*|[-+*/^(),]))", re.IGNORECASE)


class ExpressionError(ValueError):
    pass


def tokenize(source):
    tokens = []
    index = 0
    while index < len(source):
        match = TOKEN.match(source, index)
        if match is None:
            if not source[index:].strip():
                break
            raise ExpressionError("CHAR")
        index = match.end()
        number, name, operator = match.groups()
        if number is not None:
            tokens.append(("num", number))
        elif name is not None:
            tokens.append(("name", name.lower()))
        else:
            tokens.append(("op", "^" if operator == "**" else operator))
    return tokens


class _Parser:
    def __init__(self, tokens):
        self.tokens = tokens
        self.position = 0
        self.names = set()

    def peek(self):
        return self.tokens[self.position] if self.position < len(self.tokens) else None

    def take(self):
        token = self.peek()
        self.position += 1
        return token

    def is_op(self, value):
        token = self.peek()
        return token is not None and token[0] == "op" and token[1] == value

    def expect(self, value):
        if not self.is_op(value):
            raise ExpressionError("EXPECTED")
        self.position += 1

    def additive(self):
        self.multiplicative()
        while self.is_op("+") or self.is_op("-"):
            self.position += 1
            self.multiplicative()

    def multiplicative(self):
        self.unary()
        while self.is_op("*") or self.is_op("/"):
            self.position += 1
            self.unary()

    def unary(self):
        if self.is_op("-") or self.is_op("+"):
            self.position += 1
            return self.unary()
        return self.power()

    def power(self):
        self.primary()
        if self.is_op("^"):
            self.position += 1
            self.unary()

    def primary(self):
        token = self.take()
        if token is None:
            raise ExpressionError("END")
        kind, value = token
        if kind == "num":
            return
        if kind == "name":
            if self.is_op("("):
                if value not in FUNCTIONS:
                    raise ExpressionError("FUNCTION")
                self.position += 1
                if not self.is_op(")"):
                    self.additive()
                    while self.is_op(","):
                        self.position += 1
                        self.additive()
                self.expect(")")
                return
            if value not in CONSTANTS:
                self.names.add(value)
            return
        if value == "(":
            self.additive()
            self.expect(")")
            return
        raise ExpressionError("TOKEN")


def variables(source):
    if not isinstance(source, str) or not source.strip():
        raise ExpressionError("EMPTY")
    if len(source) > MAX_LENGTH:
        raise ExpressionError("LONG")
    parser = _Parser(tokenize(source))
    try:
        parser.additive()
    except RecursionError as error:
        raise ExpressionError("DEPTH") from error
    if parser.position < len(parser.tokens):
        raise ExpressionError("TOKEN")
    return parser.names


def is_formula(source):
    try:
        return variables(source) <= SCOPE
    except ExpressionError:
        return False
