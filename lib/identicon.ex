# github.com/teleganov
# Identicon generator from the Udemy Elixir tutorial

defmodule Identicon do
  @moduledoc """
  Module for generating an identicon
  """

  def main(input_string) do
    input_string
    |> Identicon.hash_input
    |> Identicon.get_color
    |> Identicon.build_grid
    |> Identicon.generate_image
    |> Identicon.save_image(input_string)
  end

  @doc """
  Hashes a given `input_string` to a list of integers (MD5)
  """
  def hash_input(input_string) do
    hex = 
      :crypto.hash(:md5, input_string)
      |> :binary.bin_to_list

    %Identicon.Image{hex: hex}
  end

  @doc """
  Appends color property to an Identicon.Image that is passed in

  ## Examples
      iex> %Identicon.Image{hex: [1, 2, 3, 4, 5, 6]} |> Identicon.get_color
      %Identicon.Image{hex: [1, 2, 3, 4, 5, 6], color: {1, 2, 3}}
  """
  def get_color(%Identicon.Image{hex: [red, green, blue | _any]} = image) do
    %Identicon.Image{image | color: {red, green, blue}}
  end

  @doc """
  Appends a grid property to an Identicon.Image

  ## Examples
      iex> %Identicon.Image{hex: [1, 2, 3]} |> Identicon.build_grid
      %Identicon.Image{color: nil, hex: [1, 2, 3], grid: [{1, 0, false}, {2, 1, true}, {3, 2, false}, {2, 3, true}, {1, 4, false}]}
  """
  def build_grid(%Identicon.Image{hex: hex_list} = image) do
    grid =
      hex_list
      |> Enum.chunk(3)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index
      |> Enum.map(&set_color/1)

    %Identicon.Image{image | grid: grid}
  end

  @doc """
  Generates an image using an Identicon.Image passed in
  """
  def generate_image(%Identicon.Image{grid: grid, color: color} = image) do
    image = :egd.create(250, 250)
    grid |> Enum.map(&fill_rectangle(&1, color, image))

    image |> :egd.render
  end

  def save_image(image, name) do
    File.write("#{name}.png", image)
  end

  ### Helper Functions ###

  def fill_rectangle({_any, index, fill} = grid_element, color, image) do
    row = Integer.floor_div(index, 5)
    col = rem(index, 5)
    width = 50

    p1 = {col * width, row * width}
    p2 = {(col + 1) * width - 1, (row + 1) * width - 1}

    case fill do
      true -> :egd.filledRectangle(image, p1, p2, :egd.color(color))
      false -> :egd.filledRectangle(image, p1, p2, :egd.color({255, 255, 255}))
    end
  end

  @doc """
  Mirrors a row of arbitrary length

  ## Examples
      iex> Identicon.mirror_row([1, 2, 3])
      [1, 2, 3, 2, 1]

      iex> Identicon.mirror_row([1, 2])
      [1, 2, 2, 1]
  """
  def mirror_row(row) do
    to_flip = 
      case row |> length |> rem(2) do
        0 -> row
        1 -> Enum.split(row, -1) |> elem(0)
      end
    row ++ Enum.reverse(to_flip)
  end

  @doc """
  Sets a flag on a given `grid_element` determining whether it should be colored based on whether its `number` is even or odd

  ## Examples
      iex> Identicon.set_color({1, 0})
      {1, 0, false}

      iex>Identicon.set_color({2, 0})
      {2, 0, true}
  """
  def set_color({number, index} = grid_element) do
    {number, index, rem(number, 2) == 0}
  end
end
