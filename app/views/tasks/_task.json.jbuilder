json.extract! task, :id, :status, :product_id, :created_at, :updated_at
json.url task_url(task, format: :json)
