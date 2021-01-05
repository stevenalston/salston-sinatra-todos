require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "todo_app")
          end
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"
    result = query(sql, id)
    tuple = result.first

    list_id = tuple["id"].to_i
    todos = find_todos(list_id)

    {id: list_id, name: tuple["name"], todos: todos}
  end

  def all_lists
    sql = "SELECT * FROM lists"
    result = query(sql)

    result.map do |tuple|
      list_id = tuple["id"].to_i
      todos = find_todos(list_id)

      { id: list_id, name: tuple["name"], todos: todos }
    end
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) values ($1)"
    query(sql, list_name)
  end

  def delete_list(id)
    query("DELETE FROM lists WHERE id = $1", id)
    query("DELETE FROM todos WHERE list_id = $1", id)

  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name= $1 WHERE id = $2"
    query(sql, new_name, id)
  end

  def create_new_todo(list_id, name)
    sql = "INSERT INTO todos (list_id, name) VALUES ($1, $2)"
    query(sql, list_id, name)
  end

  def delete_todo(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2"
    query(sql, todo_id, list_id)
  end

  def update_todo_status(list_id, todo_id, status)
    sql = "UPDATE todos SET is_completed = $1 WHERE id = $2 AND list_id = $3"
    query(sql, status, todo_id, list_id)
  end

  def mark_all_todos_completed(list_id)
    sql = "SELECT * FROM todos"
    result = query(sql)
    result.map do |t|
      t_sql = "UPDATE todos SET is_completed = true WHERE list_id = $1"
      query(t_sql, list_id)
    end
  end

  private
  def find_todos(list_id)
    todo_sql = "SELECT * FROM todos WHERE list_id = $1"
    todos_result = query(todo_sql, list_id)

    todos_result.map { |t| {id: t["id"].to_i, name: t["name"], is_completed: t["is_completed"] == "t" }}
  end
end