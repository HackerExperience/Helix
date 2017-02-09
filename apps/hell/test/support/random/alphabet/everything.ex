defmodule HELL.TestHelper.Random.Alphabet.Everything do
  @moduledoc """
  Alphabet with several characters, including unicode letters, spaces,
  punctuation etc
  """

  alias HELL.TestHelper.Random.Alphabet

  @characters "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" <>
    "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿĀāĂăĄą" <>
    "ĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏ" <>
    "ŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽž" <>
    " \n<>\#{}\\/!?@$%^&*()[]~`'\":;.,"
  @alphabet Alphabet.build_alphabet(@characters)

  def alphabet,
    do: @alphabet
end