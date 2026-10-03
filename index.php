<?php
session_start();
require 'src/db.php';

if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

$message = '';
$activeForm = 'login';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    $activeForm = $action === 'register' ? 'register' : 'login';
    $token = $_POST['csrf_token'] ?? '';

    if (!is_string($token) || !hash_equals($_SESSION['csrf_token'], $token)) {
        $message = 'Сессия формы устарела. Обновите страницу и попробуйте снова.';
    } elseif ($action === 'register') {
        $nameInput = $_POST['name'] ?? '';
        $emailInput = $_POST['email'] ?? '';
        $password = $_POST['password'] ?? '';
        $name = is_string($nameInput) ? trim($nameInput) : '';
        $email = is_string($emailInput) ? strtolower(trim($emailInput)) : '';
        $password = is_string($password) ? $password : '';

        if ($name === '' || strlen($name) > 400) {
            $message = 'Укажите имя длиной не более 100 символов.';
        } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($email) > 150) {
            $message = 'Введите корректный адрес электронной почты.';
        } elseif (strlen($password) < 8) {
            $message = 'Пароль должен содержать не менее 8 символов.';
        } else {
            try {
                $statement = $pdo->prepare(
                    'INSERT INTO users (name, email, password_hash, role) VALUES (:name, :email, :password_hash, \'user\')'
                );
                $statement->execute([
                    'name' => $name,
                    'email' => $email,
                    'password_hash' => password_hash($password, PASSWORD_DEFAULT),
                ]);

                session_regenerate_id(true);
                $_SESSION['user_id'] = (int) $pdo->lastInsertId();
                $_SESSION['user_name'] = $name;
                header('Location: index.php');
                exit;
            } catch (PDOException $exception) {
                $message = $exception->getCode() === '23000'
                    ? 'Пользователь с такой почтой уже зарегистрирован.'
                    : 'Не удалось создать аккаунт. Проверьте подключение к базе данных.';
            }
        }
    } elseif ($action === 'login') {
        $emailInput = $_POST['email'] ?? '';
        $password = $_POST['password'] ?? '';
        $email = is_string($emailInput) ? strtolower(trim($emailInput)) : '';
        $password = is_string($password) ? $password : '';

        if (filter_var($email, FILTER_VALIDATE_EMAIL) && $password !== '') {
            $statement = $pdo->prepare('SELECT id, name, password_hash FROM users WHERE email = :email LIMIT 1');
            $statement->execute(['email' => $email]);
            $user = $statement->fetch(PDO::FETCH_ASSOC);

            if ($user && password_verify($password, $user['password_hash'])) {
                session_regenerate_id(true);
                $_SESSION['user_id'] = (int) $user['id'];
                $_SESSION['user_name'] = $user['name'];
                $updateLogin = $pdo->prepare('UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = :id');
                $updateLogin->execute(['id' => $user['id']]);
                header('Location: index.php');
                exit;
            }
        }

        $message = 'Неверная почта или пароль.';
    } elseif ($action === 'logout') {
        $_SESSION = [];
        session_regenerate_id(true);
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        header('Location: index.php');
        exit;
    }
}

$isLoggedIn = isset($_SESSION['user_id']);
$escape = static fn($value) => htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#f5f4ef">
    <title>SplitBill — общий счёт без путаницы</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <main class="page-shell">
        <header class="topbar">
            <a class="brand" href="index.php" aria-label="SplitBill, главная">
                <span class="brand-mark" aria-hidden="true">S</span>
                <span>splitbill</span>
            </a>
            <span class="topbar-note">Общие расходы. Всё по-честному.</span>
        </header>

        <?php if ($isLoggedIn): ?>
            <section class="welcome-panel" aria-labelledby="welcome-title">
                <div class="welcome-copy">
                    <p class="eyebrow">Ваш аккаунт</p>
                    <h1 id="welcome-title">Рады видеть,<br><span><?= $escape($_SESSION['user_name']) ?>.</span></h1>
                    <p class="intro">Вы вошли в SplitBill. Теперь можно вместе вести расходы и делить счета.</p>
                    <form method="post" class="logout-form">
                        <input type="hidden" name="csrf_token" value="<?= $escape($_SESSION['csrf_token']) ?>">
                        <button class="button button-secondary" type="submit" name="action" value="logout">Выйти из аккаунта</button>
                    </form>
                </div>
                <div class="receipt-art" aria-hidden="true">
                    <span class="receipt-label">ОБЩИЙ СЧЁТ</span>
                    <strong>12 450 <small>₸</small></strong>
                    <span class="receipt-rule"></span>
                    <span class="receipt-row"><i></i><i></i></span>
                    <span class="receipt-row"><i></i><i></i></span>
                    <span class="receipt-row"><i></i><i></i></span>
                    <span class="receipt-total">каждый платит свою часть</span>
                </div>
            </section>
        <?php else: ?>
            <section class="auth-layout" aria-label="Регистрация и вход">
                <div class="intro-panel">
                    <p class="eyebrow">Деньги не должны портить дружбу</p>
                    <h1>Счёт общий.<br><span>Расчёт простой.</span></h1>
                    <p class="intro">Записывайте общие траты, делите расходы и точно знайте, кто кому сколько должен.</p>
                    <div class="feature-line"><span class="feature-dot"></span>Прозрачно для всей компании</div>
                    <div class="feature-line"><span class="feature-dot"></span>Никаких неловких напоминаний</div>
                    <div class="scribble" aria-hidden="true">всё сходится <span>↗</span></div>
                </div>

                <div class="auth-panel">
                    <div class="auth-heading">
                        <p class="eyebrow">Начнём</p>
                        <h2><?= $activeForm === 'register' ? 'Создать аккаунт' : 'С возвращением' ?></h2>
                    </div>
                    <div class="auth-tabs" role="tablist" aria-label="Выберите действие">
                        <button class="auth-tab <?= $activeForm === 'login' ? 'is-active' : '' ?>" type="button" role="tab" aria-selected="<?= $activeForm === 'login' ? 'true' : 'false' ?>" data-auth-tab="login">Войти</button>
                        <button class="auth-tab <?= $activeForm === 'register' ? 'is-active' : '' ?>" type="button" role="tab" aria-selected="<?= $activeForm === 'register' ? 'true' : 'false' ?>" data-auth-tab="register">Регистрация</button>
                    </div>

                    <?php if ($message !== ''): ?>
                        <p class="form-message is-error" role="alert"><?= $escape($message) ?></p>
                    <?php endif; ?>

                    <form class="auth-form <?= $activeForm === 'register' ? 'is-hidden' : '' ?>" method="post" data-auth-form="login">
                        <input type="hidden" name="csrf_token" value="<?= $escape($_SESSION['csrf_token']) ?>">
                        <label for="login-email">Электронная почта</label>
                        <input id="login-email" name="email" type="email" autocomplete="email" placeholder="you@example.com" maxlength="150" required>
                        <label for="login-password">Пароль</label>
                        <input id="login-password" name="password" type="password" autocomplete="current-password" placeholder="Ваш пароль" required>
                        <button class="button button-primary" type="submit" name="action" value="login">Войти <span aria-hidden="true">→</span></button>
                    </form>

                    <form class="auth-form <?= $activeForm === 'login' ? 'is-hidden' : '' ?>" method="post" data-auth-form="register">
                        <input type="hidden" name="csrf_token" value="<?= $escape($_SESSION['csrf_token']) ?>">
                        <label for="register-name">Ваше имя</label>
                        <input id="register-name" name="name" type="text" autocomplete="name" placeholder="Например, Алия" maxlength="100" required>
                        <label for="register-email">Электронная почта</label>
                        <input id="register-email" name="email" type="email" autocomplete="email" placeholder="you@example.com" maxlength="150" required>
                        <label for="register-password">Пароль</label>
                        <input id="register-password" name="password" type="password" autocomplete="new-password" placeholder="Не менее 8 символов" minlength="8" required>
                        <button class="button button-primary" type="submit" name="action" value="register">Создать аккаунт <span aria-hidden="true">→</span></button>
                    </form>
                    <p class="privacy-note">Ваш пароль хранится в защищённом виде.</p>
                </div>
            </section>
        <?php endif; ?>

        <footer class="site-footer"><span>splitbill</span><span>Меньше неловкости. Больше ясности.</span></footer>
    </main>
    <script src="main.js" defer></script>
</body>
</html>
