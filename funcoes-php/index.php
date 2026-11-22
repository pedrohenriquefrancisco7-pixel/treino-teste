<?php
// Arquivo: index.php
// Importa as funções e IMPRIME os resultados (o echo fica aqui, não nas funções)
require_once 'funcoes.php';
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Exercícios - Funções em PHP</title>
    <!-- Bootstrap via CDN (Aula 7) -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">

<nav class="navbar navbar-dark bg-dark mb-4">
    <div class="container">
        <span class="navbar-brand">Lista de Exercícios: Funções em PHP</span>
    </div>
</nav>

<div class="container">
    <div class="row g-4">

        <!-- Exercício 1 -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header"><strong>Exercício 1:</strong> Conversor de Moedas</div>
                <div class="card-body">
                    <?php
                    $preco = 150.00;
                    $precoDolar = converterParaDolar($preco);
                    echo "R$ " . number_format($preco, 2, ',', '.') . " = US$ " . number_format($precoDolar, 2, '.', ',');
                    ?>
                </div>
            </div>
        </div>

        <!-- Exercício 2 -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header"><strong>Exercício 2:</strong> Desconto Flexível</div>
                <div class="card-body">
                    <?php
                    $compra = 200.00;
                    echo "Compra de " . formatarMoeda($compra) . "<br>";
                    echo "Desconto padrão (5%): " . formatarMoeda(calcularValorComDesconto($compra)) . "<br>";
                    echo "Promoção (15%): " . formatarMoeda(calcularValorComDesconto($compra, 15));
                    ?>
                </div>
            </div>
        </div>

        <!-- Exercício 3 -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header"><strong>Exercício 3:</strong> Gerar Login</div>
                <div class="card-body">
                    <?php
                    echo "Marcelo Formico → <code>" . gerarLogin("Marcelo", "Formico") . "</code><br>";
                    echo "Ana Souza → <code>" . gerarLogin("Ana", "Souza") . "</code>";
                    ?>
                </div>
            </div>
        </div>

        <!-- Exercício 4 -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header"><strong>Exercício 4:</strong> Validar Senha</div>
                <div class="card-body">
                    <?php
                    $senhas = ["abc123", "senhaForte2024"];
                    foreach ($senhas as $senha) {
                        if (validarSenha($senha)) {
                            echo "<div class='alert alert-success py-1'>\"$senha\": Senha Aprovada</div>";
                        } else {
                            echo "<div class='alert alert-danger py-1'>\"$senha\": Senha muito curta</div>";
                        }
                    }
                    ?>
                </div>
            </div>
        </div>

        <!-- Exercício 5 -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header"><strong>Exercício 5:</strong> Frete (Early Return)</div>
                <div class="card-body">
                    <?php
                    echo "1500 km, 10 kg: " . calcularFrete(1500, 10) . "<br>";
                    echo "300 km, 80 kg: " . calcularFrete(300, 80) . "<br>";
                    echo "300 km, 20 kg: " . formatarMoeda(calcularFrete(300, 20));
                    ?>
                </div>
            </div>
        </div>

        <!-- Exercício 6 -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header"><strong>Exercício 6:</strong> Correção de Escopo</div>
                <div class="card-body">
                    <?php
                    $imposto = 0.15;
                    // Agora o imposto entra na função como parâmetro
                    echo "Tributo: " . calcularTributo(100, $imposto);
                    ?>
                </div>
            </div>
        </div>

        <!-- Exercício 7 -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header"><strong>Exercício 7:</strong> Produto Bloqueado</div>
                <div class="card-body">
                    <?php
                    $produtos = ["A12", "C30", "X99"];
                    foreach ($produtos as $codigo) {
                        if (verificarProdutoBloqueado($codigo)) {
                            echo "Produto $codigo: <span class='badge bg-danger'>Bloqueado</span><br>";
                        } else {
                            echo "Produto $codigo: <span class='badge bg-success'>Liberado</span><br>";
                        }
                    }
                    ?>
                </div>
            </div>
        </div>

        <!-- Exercício 8 -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header"><strong>Exercício 8:</strong> Sanitização (XSS)</div>
                <div class="card-body">
                    <?php
                    $formulario = [
                        "nome" => "   <b>Pedro</b>   ",
                        "bio"  => "<script>alert('hackeado!');</script>",
                    ];
                    $limpo = limparDadosFormulario($formulario);

                    echo "<strong>Nome:</strong> " . $limpo["nome"] . "<br>";
                    echo "<strong>Bio:</strong> " . $limpo["bio"];
                    // As tags aparecem como texto e NÃO são executadas pelo navegador
                    ?>
                </div>
            </div>
        </div>

        <!-- Exercício 9 -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header"><strong>Exercício 9:</strong> Helper de UI (Painel de Pagamentos)</div>
                <div class="card-body p-0">
                    <table class="table table-striped mb-0">
                        <thead>
                            <tr><th>Cliente</th><th>Status</th></tr>
                        </thead>
                        <tbody>
                            <tr><td>Ana</td><td><?= gerarBadgeStatus("pago") ?></td></tr>
                            <tr><td>Bruno</td><td><?= gerarBadgeStatus("pendente") ?></td></tr>
                            <tr><td>Carla</td><td><?= gerarBadgeStatus("cancelado") ?></td></tr>
                            <tr><td>Diego</td><td><?= gerarBadgeStatus("estornado") ?></td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- Exercício 10 -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header"><strong>Exercício 10:</strong> Gerador de Holerite</div>
                <div class="card-body">
                    <?= gerarHolerite("Carlos", 4500.00) ?>
                </div>
            </div>
        </div>

    </div>
</div>

<footer class="text-center text-muted py-4">Projeto Integrador II - Funções em PHP</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
