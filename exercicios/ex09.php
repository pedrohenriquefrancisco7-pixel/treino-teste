<?php
// Exercício 9: Helper de UI
// Retorna um badge do Bootstrap de acordo com o status do pagamento

function gerarBadgeStatus(string $status): string
{
    return match ($status) {
        "pago"      => '<span class="badge bg-success">Pago</span>',
        "pendente"  => '<span class="badge bg-warning text-dark">Aguardando</span>',
        "cancelado" => '<span class="badge bg-danger">Cancelado</span>',
        default     => '<span class="badge bg-secondary">Desconhecido</span>',
    };
}
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Painel de Pagamentos</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container mt-5">
        <h2 class="mb-4">Painel de Pagamentos</h2>

        <table class="table table-striped table-bordered bg-white">
            <thead class="table-dark">
                <tr>
                    <th>Cliente</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>Ana</td>
                    <td><?= gerarBadgeStatus("pago") ?></td>
                </tr>
                <tr>
                    <td>Bruno</td>
                    <td><?= gerarBadgeStatus("pendente") ?></td>
                </tr>
                <tr>
                    <td>Carla</td>
                    <td><?= gerarBadgeStatus("cancelado") ?></td>
                </tr>
                <tr>
                    <td>Diego</td>
                    <td><?= gerarBadgeStatus("estornado") ?></td>
                </tr>
            </tbody>
        </table>
    </div>
</body>
</html>
