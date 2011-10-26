function h = test_handle(name)
  h.name = name;
  h.get_name = @get_name;
  h.set_name = @set_name;

  function set_name(name)
    h.name = name;
  end

  function n = get_name()
    n = h.name;
  end

end
