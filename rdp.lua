-- Grammar:
-- Expr    -> Term (('+' | '-') Term)*
-- Term    -> Factor (('*' | '/') Factor)*
-- Factor  -> '(' Expr ')' | Num
-- Num     -> [0-9]+

-- Tokens:
Token = {
    Number = function(value) return { type = "Number", value = value } end,
    Addition = { type = "Addition" },
    Subtraction = { type = "Subtraction" },
    Multiplication = { type = "Multiplication" },
    Division = { type = "Division" },
    LParen = { type = "LParen" },
    RParen = { type = "RParen" },
    EOF = { type = "EOF" }
}

-- Lexer:
Lexer = {}
Lexer.__index = Lexer

function Lexer.new(input)
    local self = setmetatable({}, Lexer)
    self.input = input
    self.position = 1
    self.current_char = input:sub(self.position, self.position)
    return self
end

function Lexer:advance()
    self.position = self.position + 1
    if self.position > #self.input then
        self.current_char = nil
    else
        self.current_char = self.input:sub(self.position, self.position)
    end
end

function Lexer:get_next_token()
    while self.current_char do
        if self.current_char:match("%d") then
            return self:number()
        elseif self.current_char == '+' then
            self:advance()
            return Token.Addition
        elseif self.current_char == '-' then
            self:advance()
            return Token.Subtraction
        elseif self.current_char == '*' then
            self:advance()
            return Token.Multiplication
        elseif self.current_char == '/' then
            self:advance()
            return Token.Division
        elseif self.current_char == '(' then
            self:advance()
            return Token.LParen
        elseif self.current_char == ')' then
            self:advance()
            return Token.RParen
        elseif self.current_char:match("%s") then
            self:advance()
        else
            error("Caractere desconhecido: " .. self.current_char)
        end
    end
    return Token.EOF
end

function Lexer:number()
    local value = 0
    while self.current_char and self.current_char:match("%d") do
        value = value * 10 + tonumber(self.current_char)
        self:advance()
    end
    return Token.Number(value)
end

-- Parser:
Parser = {}
Parser.__index = Parser

function Parser.new(lexer)
    local self = setmetatable({}, Parser)
    self.lexer = lexer
    self.current_token = lexer:get_next_token()
    return self
end

function Parser:eat(token_type)
    if self.current_token.type == token_type then
        self.current_token = self.lexer:get_next_token()
    else
        error("Token inesperado: " .. self.current_token.type .. ", esperado: " .. token_type)
    end
end

function Parser:factor()
    if self.current_token.type == "Number" then
        local value = self.current_token.value
        self:eat("Number")
        return { type = "Number", value = value }
    elseif self.current_token.type == "LParen" then
        self:eat("LParen")
        local node = self:expr()
        self:eat("RParen")
        return node
    else
        error("Token inesperado em factor: " .. self.current_token.type)
    end
end

function Parser:term()
    local node = self:factor()
    while self.current_token.type == "Multiplication" or self.current_token.type == "Division" do
        local op = self.current_token
        if op.type == "Multiplication" then
            self:eat("Multiplication")
        elseif op.type == "Division" then
            self:eat("Division")
        end
        node = { type = "BinaryOp", left = node, op = op, right = self:factor() }
    end
    return node
end

function Parser:expr()
    local node = self:term()
    while self.current_token.type == "Addition" or self.current_token.type == "Subtraction" do
        local op = self.current_token
        if op.type == "Addition" then
            self:eat("Addition")
        elseif op.type == "Subtraction" then
            self:eat("Subtraction")
        end
        node = { type = "BinaryOp", left = node, op = op, right = self:term() }
    end
    return node
end

function Parser:parse()
    return self:expr()
end

-- AST:
function format_node(node, level)
    local indent = string.rep("  ", level)
    if node.type == "Number" then
        return indent .. "Number(" .. node.value .. ")\n"
    elseif node.type == "BinaryOp" then
        local op_str = node.op.type
        return indent .. "BinaryOp(" .. op_str .. ",\n" .. format_node(node.left, level + 1) .. format_node(node.right, level + 1) .. indent .. ")\n"
    end
end

function evaluate_node(node)
    if node.type == "Number" then
        return node.value
    elseif node.type == "BinaryOp" then
        local left_value = evaluate_node(node.left)
        local right_value = evaluate_node(node.right)
        if node.op.type == "Addition" then
            return left_value + right_value
        elseif node.op.type == "Subtraction" then
            return left_value - right_value
        elseif node.op.type == "Multiplication" then
            return left_value * right_value
        elseif node.op.type == "Division" then
            return left_value / right_value
        end
    end
end

-- "Main":
local input = "3 + 5 * (10 - 4)"
-- local input = "(3 + 1 * 2) / (3 - 1 * 2)"
local lexer = Lexer.new(input)
local parser = Parser.new(lexer)
local ast = parser:parse()
local result = evaluate_node(ast)
print(format_node(ast, 0))
print("Result: " .. result)
