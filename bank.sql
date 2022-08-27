CREATE TABLE `bank` (
  `id` int(11) NOT NULL,
  `identifier` varchar(60) NOT NULL,
  `iban` int(4) NOT NULL,
  `mdp` int(3) NOT NULL,
  `proprietaire` varchar(25) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `bank`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `bank`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;
COMMIT;
