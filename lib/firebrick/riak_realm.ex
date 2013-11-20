defmodule Firebrick.RiakRealm do
  defmacro __using__([]) do
    quote do

      import Firebrick.RiakRealm

      def assign_attributes(record, params) do
        Enum.reduce(params, record, fn({param, value}, updated_record)->
          apply(updated_record, :"#{param}", [value])
        end)
      end
      defoverridable [assign_attributes: 2]


      def public_attributes(record) do
        lc attr inlist safe_attributes do
          { "#{attr}", apply(record, :"#{attr}", []) }
        end
      end


      def find(obj_id) do
        data = get(bucket, obj_id)
        assign_attributes(__MODULE__[id: obj_id], data)
      end


      def saveable_attributes(record) do
        clean_attrs = Enum.reduce skip_attributes, record.attributes, fn(attr, attrs)->
          ListDict.delete(attrs, attr)
        end
        Enum.filter(clean_attrs, fn({attr, value})-> value != nil end)
      end


      def save(record) do
        record = record.validate
        if length(record.errors) == 0 do
          id = record.id || :undefined
          bucket = tuple_to_list(record) |> hd |> apply(:bucket, [])

          case record.id do
            nil ->
              {:ok, put(bucket, :undefined, record.saveable_attributes) }
            _ ->
              {:ok, patch(bucket, id, record.saveable_attributes) }
          end
        else
          {:error, record}
        end
      end


      def search(query, options // []) do
        {:ok, {:search_results, search_results, _, count}} = RiakPool.run(fn(worker)->
          :riakc_pb_socket.search(worker, bucket, query, options)
        end)

        # Cleans up, by removing the bucket names from the results
        results = :lists.map(fn(item)->
          {_, obj} = item
          obj
        end, search_results)

        models = lc result inlist results, do: assign_attributes(__MODULE__[], result)

        # Returns {results, total_number_of_results}
        {models, count}
      end


      def destroy(arg1) do
        cond do
          is_binary(arg1) ->
            RiakPool.delete(bucket, arg1)
          is_record(arg1) && arg1.id != nil ->
            RiakPool.delete(bucket, arg1.id)
          true ->
            :ok
        end
      end

    end
  end


  def put(bucket, key, data) do
    {:ok, json} = JSEX.encode data
    result = :riakc_obj.new(bucket, key, json, "application/json") |> RiakPool.put
    cond do
      key == :undefined ->
        :riakc_obj.key([result][:ok])
      true ->
        key
    end
  end


  def get(bucket, key) do
    {:ok, obj} = RiakPool.get(bucket, key)
    {:ok, data} = :riakc_obj.get_values(obj)
    |> hd
    |> JSEX.decode
    data
  end


  def patch(bucket, key, patch_data) do
    new_data = get(bucket, key) |> Dict.merge(patch_data)
    {:ok, json} = JSEX.encode(new_data)
    :ok = :riakc_obj.new(bucket, key, json, "application/json")
    |> RiakPool.put
    key
  end
end