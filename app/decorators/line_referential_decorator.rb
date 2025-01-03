class LineReferentialDecorator < Af83::Decorator
  decorates LineReferential
  set_scope { [context[:workbench]] }
end
