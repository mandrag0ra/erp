# module ExternalApiAdaptable
# this module is intended to adapt easily Ekylibre
# to external APIs just by telling the controller
# how to translate API input/output to its Ekylibre equivalent
# this controller actions builder assumes that the controller's name
# is the API output name.

module ExternalApiAdaptable
  extend ActiveSupport::Concern

  module ClassMethods
    def manage_restfully(defaults = {})
      options = defaults.extract! :only, :except
      actions  = [:index, :show, :new, :create, :edit, :update, :destroy]
      actions &= [options[:only]].flatten   if options[:only]
      actions -= [options[:except]].flatten if options[:except]

      name = self.controller_name
      model = defaults[:model].present? ? defaults[:model].to_s.singularize.classify.constantize : name.to_s.singularize.classify.constantize
      model = model.send defaults[:scope] if defaults[:scope].present?

      output_name = name

      methods =
        {
          index:  lambda{@records = model.all; render template: 'layouts/json/index', locals:{output_name: output_name}},
          show:   lambda{@record = model.find(permitted_params[:id]); render template: 'layouts/json/show', locals:{output_name: output_name.to_s.singularize}}
        }

      actions.each do |action|
        define_method action, methods[action]
      end

      define_method :permitted_params do
        params.permit!
      end
      private :permitted_params
    end
  end
end
