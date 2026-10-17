-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1
-- Время создания: Окт 17 2026 г., 10:02
-- Версия сервера: 10.4.32-MariaDB
-- Версия PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `splitbill1`
--

-- --------------------------------------------------------

--
-- Структура таблицы `bill_groups`
--

CREATE TABLE `bill_groups` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `expenses`
--

CREATE TABLE `expenses` (
  `id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  `paid_by_user_id` int(11) NOT NULL,
  `created_by_user_id` int(11) NOT NULL,
  `description` varchar(255) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'KZT',
  `split_mode` enum('equal','custom') NOT NULL DEFAULT 'equal',
  `spent_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `expense_splits`
--

CREATE TABLE `expense_splits` (
  `expense_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `share_amount` decimal(12,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `groups`
--

CREATE TABLE `groups` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='сами группы';

-- --------------------------------------------------------

--
-- Структура таблицы `group_members`
--

CREATE TABLE `group_members` (
  `group_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `role` enum('owner','member') NOT NULL DEFAULT 'member',
  `joined_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `settlements`
--

CREATE TABLE `settlements` (
  `id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  `from_user_id` int(11) NOT NULL,
  `to_user_id` int(11) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `settled_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('user','admin') NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `avatar` varchar(255) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'KZT',
  `is_verifies` tinyint(1) NOT NULL DEFAULT 0,
  `last_login` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `role`, `created_at`, `avatar`, `phone`, `currency`, `is_verifies`, `last_login`) VALUES
(1, '404', '404pilotver@gmail.com', '$2y$10$PFlgb6zHHmK051rUliA4RO46rX0kfVD1fhWo3fxo9csW5yNZhiZvm', 'user', '2026-10-03 11:06:49', NULL, NULL, 'KZT', 0, NULL);

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `bill_groups`
--
ALTER TABLE `bill_groups`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_bill_groups_created_by` (`created_by`);

--
-- Индексы таблицы `expenses`
--
ALTER TABLE `expenses`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_expenses_id_group_id` (`id`,`group_id`),
  ADD KEY `idx_expenses_group_spent_at` (`group_id`,`spent_at`),
  ADD KEY `idx_expenses_paid_by` (`paid_by_user_id`),
  ADD KEY `idx_expenses_created_by` (`created_by_user_id`),
  ADD KEY `fk_expenses_payer_membership` (`group_id`,`paid_by_user_id`),
  ADD KEY `fk_expenses_creator_membership` (`group_id`,`created_by_user_id`);

--
-- Индексы таблицы `expense_splits`
--
ALTER TABLE `expense_splits`
  ADD PRIMARY KEY (`expense_id`,`user_id`),
  ADD KEY `idx_expense_splits_group_user` (`group_id`,`user_id`),
  ADD KEY `fk_expense_splits_expense` (`expense_id`,`group_id`);

--
-- Индексы таблицы `groups`
--
ALTER TABLE `groups`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `group_members`
--
ALTER TABLE `group_members`
  ADD PRIMARY KEY (`group_id`,`user_id`),
  ADD KEY `idx_group_members_user_id` (`user_id`);

--
-- Индексы таблицы `settlements`
--
ALTER TABLE `settlements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_settlements_group` (`group_id`),
  ADD KEY `fk_settlements_from` (`group_id`,`from_user_id`),
  ADD KEY `fk_settlements_to` (`group_id`,`to_user_id`);

--
-- Индексы таблицы `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `bill_groups`
--
ALTER TABLE `bill_groups`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `expenses`
--
ALTER TABLE `expenses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `groups`
--
ALTER TABLE `groups`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `settlements`
--
ALTER TABLE `settlements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `bill_groups`
--
ALTER TABLE `bill_groups`
  ADD CONSTRAINT `fk_bill_groups_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `expenses`
--
ALTER TABLE `expenses`
  ADD CONSTRAINT `fk_expenses_creator_membership` FOREIGN KEY (`group_id`,`created_by_user_id`) REFERENCES `group_members` (`group_id`, `user_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_expenses_group` FOREIGN KEY (`group_id`) REFERENCES `bill_groups` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_expenses_payer_membership` FOREIGN KEY (`group_id`,`paid_by_user_id`) REFERENCES `group_members` (`group_id`, `user_id`) ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `expense_splits`
--
ALTER TABLE `expense_splits`
  ADD CONSTRAINT `fk_expense_splits_expense` FOREIGN KEY (`expense_id`,`group_id`) REFERENCES `expenses` (`id`, `group_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_expense_splits_member` FOREIGN KEY (`group_id`,`user_id`) REFERENCES `group_members` (`group_id`, `user_id`) ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `group_members`
--
ALTER TABLE `group_members`
  ADD CONSTRAINT `fk_group_members_group` FOREIGN KEY (`group_id`) REFERENCES `bill_groups` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_group_members_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `settlements`
--
ALTER TABLE `settlements`
  ADD CONSTRAINT `fk_settlements_from` FOREIGN KEY (`group_id`,`from_user_id`) REFERENCES `group_members` (`group_id`, `user_id`),
  ADD CONSTRAINT `fk_settlements_to` FOREIGN KEY (`group_id`,`to_user_id`) REFERENCES `group_members` (`group_id`, `user_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
