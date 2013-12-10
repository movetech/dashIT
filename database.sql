-- phpMyAdmin SQL Dump
-- version 3.5.8.2
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Erstellungszeit: 09. Dez 2013 um 16:57
-- Server Version: 5.1.69
-- PHP-Version: 5.3.3

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Datenbank: `movetech-stat`
--

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `information`
--

CREATE TABLE IF NOT EXISTS `information` (
  `lastUpdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `messages`
--

CREATE TABLE IF NOT EXISTS `messages` (
  `messageId` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serverId` int(11) NOT NULL,
  `received` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `mailId` varchar(100) DEFAULT NULL,
  `subject` varchar(250) NOT NULL,
  `message` text NOT NULL,
  `bad` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`messageId`),
  UNIQUE KEY `mailId` (`mailId`),
  KEY `serverId` (`serverId`),
  KEY `received` (`received`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1911 ;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `pauses`
--

CREATE TABLE IF NOT EXISTS `pauses` (
  `serverId` int(11) NOT NULL,
  `beginWeekday` int(11) NOT NULL,
  `beginHour` int(11) NOT NULL,
  `endWeekday` int(11) NOT NULL,
  `endHour` int(11) NOT NULL,
  PRIMARY KEY (`beginWeekday`,`beginHour`,`endWeekday`,`endHour`,`serverId`),
  KEY `serverId` (`serverId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `rules`
--

CREATE TABLE IF NOT EXISTS `rules` (
  `serverId` int(11) NOT NULL,
  `rule` varchar(200) NOT NULL,
  PRIMARY KEY (`serverId`,`rule`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `servers`
--

CREATE TABLE IF NOT EXISTS `servers` (
  `serverId` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `sender` varchar(100) NOT NULL,
  `interval` int(11) NOT NULL,
  PRIMARY KEY (`serverId`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=54 ;

--
-- Constraints der exportierten Tabellen
--

--
-- Constraints der Tabelle `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`serverId`) REFERENCES `servers` (`serverId`) ON DELETE CASCADE;

--
-- Constraints der Tabelle `pauses`
--
ALTER TABLE `pauses`
  ADD CONSTRAINT `pauses_ibfk_1` FOREIGN KEY (`serverId`) REFERENCES `servers` (`serverId`) ON DELETE CASCADE;

--
-- Constraints der Tabelle `rules`
--
ALTER TABLE `rules`
  ADD CONSTRAINT `rules_ibfk_1` FOREIGN KEY (`serverId`) REFERENCES `servers` (`serverId`) ON DELETE CASCADE;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
