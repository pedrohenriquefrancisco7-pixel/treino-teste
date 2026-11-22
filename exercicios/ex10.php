<?php
// Exercício 10: Integração Total (Gerador de Holerite)

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

// Função controladora: chama as outras funções e monta o Card do Bootstrap
function gerarHolerite(string $nome, float $salarioBruto): string
{
    $inss = calcularINSS($salarioBruto);
    $irpf = calcularIRPF($salarioBruto);
    $descontos = $inss + $irpf;
    $salarioLiquido = $salarioBruto - $descontos;

    $brutoFmt     = "R$ " . number_format($salarioBruto, 2, ',', '.');
    $inssFmt      = "R$ " . number_format($inss, 2, ',', '.');
    $irpfFmt      = "R$ " . number_format($irpf, 2, ',', '.');
    $descontosFmt = "R$ " . number_format($descontos, 2, ',', '.');
    $liquidoFmt   = "R$ " . number_format($salarioLiquido, 2, ',', '.');

    return "
    <div class='card shadow-sm' style='max-width: 400px;'>
        <div class='card-header bg-primary text-white'>
            <h5 class='mb-0'>Holerite</h5>
        </div>
        <div class='card-body'>
            <h5 class='card-title'>Funcionário: {$nome}</h5>
            <ul class='list-group list-group-flush'>
                <li class='list-group-item'><strong>Salário Bruto:</strong> {$brutoFmt}</li>
                <li class='list-group-item text-danger'>INSS (8%): - {$inssFmt}</li>
                <li class='list-group-item text-danger'>IRPF (15%): - {$irpfFmt}</li>
                <li class='list-group-item'><strong>Total de Descontos:</strong> {$descontosFmt}</li>
            </ul>
        </div>
        <div class='card-footer'>
            <strong>Salário Líquido:</strong>
            <span class='text-success fw-bold'>{$liquidoFmt}</span>
        </div>
    </div>";
}
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gerador de Holerite</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container mt-5">
        <h2 class="mb-4">Sistema de RH</h2>

        <?= gerarHolerite("Carlos", 4500.00) ?>
    </div>
</body>
</html>
