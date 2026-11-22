<?php
// Arquivo: funcoes.php
// Lista de Exercícios - Funções em PHP (Aula 10.1)
// Regra do Back-end: a função processa e RETORNA (return); quem imprime (echo) é o index.php.

// ---------------------------------------------------------------
// Exercício 1: Conversor de Moedas
// Taxa fixa: 1 Dólar = R$ 5,00
// ---------------------------------------------------------------
function converterParaDolar(float $valorReais): float
{
    $taxaCambio = 5.00;
    return $valorReais / $taxaCambio;
}

// ---------------------------------------------------------------
// Exercício 2: Desconto Flexível
// $percentualDesconto é opcional (padrão = 5%)
// ---------------------------------------------------------------
function calcularValorComDesconto(float $valorCompra, float $percentualDesconto = 5): float
{
    $desconto = $valorCompra * ($percentualDesconto / 100);
    return $valorCompra - $desconto;
}

// ---------------------------------------------------------------
// Exercício 3: Múltiplos Parâmetros e Concatenação
// Primeira letra do nome + sobrenome completo, tudo minúsculo
// ---------------------------------------------------------------
function gerarLogin(string $nome, string $sobrenome): string
{
    $login = $nome[0] . $sobrenome;   // primeira letra do nome + sobrenome
    return strtolower($login);         // "Marcelo" + "Formico" => "mformico"
}

// ---------------------------------------------------------------
// Exercício 4: Validação Booleana com Type Hinting
// Senha válida = 8 ou mais caracteres
// ---------------------------------------------------------------
function validarSenha(string $senha): bool
{
    if (strlen($senha) >= 8) {
        return true;
    }
    return false;
}

// ---------------------------------------------------------------
// Exercício 5: Early Return (Retorno Antecipado) - sem usar else
// ---------------------------------------------------------------
function calcularFrete(float $distancia, float $peso): string|float
{
    if ($distancia > 1000) {
        return "Entrega não suportada";
    }

    if ($peso > 50) {
        return "Carga muito pesada";
    }

    return $distancia * 0.5;
}

// ---------------------------------------------------------------
// Exercício 6: Correção de Bug (Problema de Escopo)
// ---------------------------------------------------------------
/*
 * CÓDIGO ORIGINAL DO ESTAGIÁRIO (com bug):
 *
 *   $imposto = 0.15;
 *
 *   function calcularTributo($valor) {
 *       return $valor * $imposto;
 *   }
 *
 *   echo "Tributo: " . calcularTributo(100);
 *
 * POR QUE NÃO FUNCIONA?
 * Pela "Regra de Las Vegas" (escopo das variáveis): o que acontece dentro
 * da função, fica dentro da função. A variável $imposto foi criada FORA da
 * função (escopo global), então ela NÃO EXISTE dentro de calcularTributo().
 * O PHP trata $imposto como indefinida lá dentro (Warning: Undefined variable),
 * e a multiplicação de um número por null gera erro/resultado errado
 * (no PHP 8, "Unsupported operand types" => Fatal Error em produção).
 *
 * CORREÇÃO:
 * Passar o imposto como PARÂMETRO da função, respeitando o isolamento do escopo.
 */
function calcularTributo(float $valor, float $imposto): float
{
    return $valor * $imposto;
}

// ---------------------------------------------------------------
// Exercício 7: Arrays e Funções (Buscador)
// ---------------------------------------------------------------
function verificarProdutoBloqueado(string $codigoProduto): bool
{
    $bloqueados = ["A12", "B45", "X99"];
    return in_array($codigoProduto, $bloqueados);
}

// ---------------------------------------------------------------
// Exercício 8: Sanitização de Dados (Segurança XSS)
// ---------------------------------------------------------------
function limparDadosFormulario(array $dadosBrutos): array
{
    $dadosLimpos = [];

    foreach ($dadosBrutos as $chave => $valor) {
        $dadosLimpos[$chave] = htmlspecialchars(trim($valor));
    }

    return $dadosLimpos;
}

// ---------------------------------------------------------------
// Exercício 9: Helper de UI (badges do Bootstrap com match)
// ---------------------------------------------------------------
function gerarBadgeStatus(string $status): string
{
    return match ($status) {
        "pago"      => '<span class="badge bg-success">Pago</span>',
        "pendente"  => '<span class="badge bg-warning text-dark">Aguardando</span>',
        "cancelado" => '<span class="badge bg-danger">Cancelado</span>',
        default     => '<span class="badge bg-secondary">Desconhecido</span>',
    };
}

// ---------------------------------------------------------------
// Exercício 10: Integração Total (Gerador de Holerite)
// ---------------------------------------------------------------
function calcularINSS(float $salario): float
{
    return $salario * 0.08;
}

function calcularIRPF(float $salario): float
{
    if ($salario > 3000) {
        return $salario * 0.15;
    }
    return 0;
}

// Helper de formatação (igual ao Lab da Aula 10)
function formatarMoeda(float $valor): string
{
    return "R$ " . number_format($valor, 2, ',', '.');
}

// Função "controladora": chama as outras funções e monta o Card do Bootstrap
function gerarHolerite(string $nome, float $salarioBruto): string
{
    $inss = calcularINSS($salarioBruto);
    $irpf = calcularIRPF($salarioBruto);
    $totalDescontos = $inss + $irpf;
    $salarioLiquido = $salarioBruto - $totalDescontos;

    return "
    <div class='card shadow-sm' style='max-width: 400px;'>
        <div class='card-header bg-primary text-white'>
            <h5 class='mb-0'>Holerite</h5>
        </div>
        <div class='card-body'>
            <h5 class='card-title'>{$nome}</h5>
            <ul class='list-group list-group-flush'>
                <li class='list-group-item d-flex justify-content-between'>
                    <span>Salário Bruto</span><strong>" . formatarMoeda($salarioBruto) . "</strong>
                </li>
                <li class='list-group-item d-flex justify-content-between text-danger'>
                    <span>INSS (8%)</span><span>- " . formatarMoeda($inss) . "</span>
                </li>
                <li class='list-group-item d-flex justify-content-between text-danger'>
                    <span>IRPF (15%)</span><span>- " . formatarMoeda($irpf) . "</span>
                </li>
                <li class='list-group-item d-flex justify-content-between'>
                    <span>Total de Descontos</span><span>" . formatarMoeda($totalDescontos) . "</span>
                </li>
            </ul>
        </div>
        <div class='card-footer d-flex justify-content-between'>
            <strong>Salário Líquido</strong>
            <strong class='text-success'>" . formatarMoeda($salarioLiquido) . "</strong>
        </div>
    </div>";
}
