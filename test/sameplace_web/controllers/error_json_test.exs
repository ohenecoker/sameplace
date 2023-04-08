defmodule SameplaceWeb.ErrorJSONTest do
  use SameplaceWeb.ConnCase, async: true

  test "renders 404" do
    assert SameplaceWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert SameplaceWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
